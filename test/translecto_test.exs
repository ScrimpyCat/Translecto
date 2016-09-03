defmodule TranslectoTest do
    use ExUnit.Case
    use Translecto.Query

    defmodule Model do
        defmodule Locale do
            use Ecto.Schema

            schema "locales" do
                field :country, :string
                field :language, :string
            end
        end

        defmodule IngredientNameTranslation do
            use Ecto.Schema
            use Translecto.Schema.Translation

            schema "ingredient_name_translations" do
                translation
                field :term, :string
            end
        end

        defmodule IngredientTypeTranslation do
            use Ecto.Schema
            use Translecto.Schema.Translation

            schema "ingredient_type_translations" do
                translation
                field :term, :string
            end
        end

        defmodule Ingredient do
            use Ecto.Schema
            use Translecto.Schema.Translatable

            schema "ingredients" do
                translatable :name, IngredientNameTranslation
                translatable :type, IngredientTypeTranslation
            end
        end

    end

    test "get_translation" do
        assert Model.Ingredient.get_translation(:name) == Model.IngredientNameTranslation
        assert Model.Ingredient.get_translation(:type) == Model.IngredientTypeTranslation
    end

    test "translate bindings" do
        locale = 1
        table = Model.Ingredient
        query = from i in table,
            locale: ^locale,
            translate: name in i.name

        result = from i in Model.Ingredient,
            join: name in Model.IngredientNameTranslation,
            where: i.name == name.translate_id and name.locale_id == ^locale

        assert inspect(query) == inspect(result)
    end

    test "translate name" do
        query = from i in Model.Ingredient,
            locale: 1,
            translate: name in i.name

        result = from i in Model.Ingredient,
            join: name in Model.IngredientNameTranslation,
            where: i.name == name.translate_id and name.locale_id == 1

        assert inspect(query) == inspect(result)
    end

    test "translate type" do
        query = from i in Model.Ingredient,
            locale: 1,
            translate: type in i.type

        result = from i in Model.Ingredient,
            join: type in Model.IngredientTypeTranslation,
            where: i.type == type.translate_id and type.locale_id == 1

        assert inspect(query) == inspect(result)
    end

    test "translate name and type" do
        query = from i in Model.Ingredient,
            locale: 1,
            translate: name in i.name,
            translate: type in i.type

        result = from i in Model.Ingredient,
            join: name in Model.IngredientNameTranslation,
            where: i.name == name.translate_id and name.locale_id == 1,
            join: type in Model.IngredientTypeTranslation,
            where: i.type == type.translate_id and type.locale_id == 1

        assert inspect(query) == inspect(result)
    end

    test "translate name and type with referencing translations" do
        query = from i in Model.Ingredient,
            locale: 1,
            translate: name in i.name,
            translate: type in i.type,
            select: { name.term, type.term }

        result = from i in Model.Ingredient,
            join: name in Model.IngredientNameTranslation,
            where: i.name == name.translate_id and name.locale_id == 1,
            join: type in Model.IngredientTypeTranslation,
            where: i.type == type.translate_id and type.locale_id == 1,
            select: { name.term, type.term }

        assert inspect(query) == inspect(result)
    end

    test "translate name and type with different locales" do
        query = from i in Model.Ingredient,
            locale: 1,
            translate: name in i.name,
            locale: 2,
            translate: type in i.type

        result = from i in Model.Ingredient,
            join: name in Model.IngredientNameTranslation,
            where: i.name == name.translate_id and name.locale_id == 1,
            join: type in Model.IngredientTypeTranslation,
            where: i.type == type.translate_id and type.locale_id == 2

        assert inspect(query) == inspect(result)
    end
end
