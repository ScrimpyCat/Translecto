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
                translation()
                field :term, :string
            end
        end

        defmodule IngredientTypeTranslation do
            use Ecto.Schema
            use Translecto.Schema.Translation

            schema "ingredient_type_translations" do
                translation()
                field :term, :string
            end
        end

        defmodule IngredientDescTranslation do
            use Ecto.Schema
            use Translecto.Schema.Translation

            schema "ingredient_desc_translations" do
                translation()
                field :term, :string
            end
        end

        defmodule Ingredient do
            use Ecto.Schema
            use Translecto.Schema.Translatable

            schema "ingredients" do
                translatable :name, IngredientNameTranslation
                translatable :type, IngredientTypeTranslation
                translatable :desc, IngredientDescTranslation
            end
        end

        defmodule Item do
            use Ecto.Schema

            schema "items" do
                belongs_to :ingredient, Ingredient
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
            left_join: name in Model.IngredientNameTranslation,
            on: i.name == name.translate_id and name.locale_id == ^locale

        assert inspect(query) == inspect(result)
    end

    test "translate name" do
        query = from i in Model.Ingredient,
            locale: 1,
            translate: name in i.name

        result = from i in Model.Ingredient,
            left_join: name in Model.IngredientNameTranslation,
            on: i.name == name.translate_id and name.locale_id == 1

        assert inspect(query) == inspect(result)
    end

    test "translate type" do
        query = from i in Model.Ingredient,
            locale: 1,
            translate: type in i.type

        result = from i in Model.Ingredient,
            left_join: type in Model.IngredientTypeTranslation,
            on: i.type == type.translate_id and type.locale_id == 1

        assert inspect(query) == inspect(result)
    end

    test "translate name and type" do
        query = from i in Model.Ingredient,
            locale: 1,
            translate: name in i.name,
            translate: type in i.type

        result = from i in Model.Ingredient,
            left_join: name in Model.IngredientNameTranslation,
            on: i.name == name.translate_id and name.locale_id == 1,
            left_join: type in Model.IngredientTypeTranslation,
            on: i.type == type.translate_id and type.locale_id == 1

        assert inspect(query) == inspect(result)
    end

    test "translate name and type with referencing translations" do
        query = from i in Model.Ingredient,
            locale: 1,
            translate: name in i.name,
            translate: type in i.type,
            select: { name.term, type.term }

        result = from i in Model.Ingredient,
            left_join: name in Model.IngredientNameTranslation,
            on: i.name == name.translate_id and name.locale_id == 1,
            left_join: type in Model.IngredientTypeTranslation,
            on: i.type == type.translate_id and type.locale_id == 1,
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
            left_join: name in Model.IngredientNameTranslation,
            on: i.name == name.translate_id and name.locale_id == 1,
            left_join: type in Model.IngredientTypeTranslation,
            on: i.type == type.translate_id and type.locale_id == 2

        assert inspect(query) == inspect(result)
    end

    test "translate bindings with list of locales" do
        locale = [1]
        table = Model.Ingredient
        query = from i in table,
            locales: ^locale,
            translate: name in i.name

        result = from i in Model.Ingredient,
            left_join: name in Model.IngredientNameTranslation,
            on: i.name == name.translate_id and name.locale_id in ^locale

        assert inspect(query) == inspect(result)
    end

    test "translate name with list of locales" do
        query = from i in Model.Ingredient,
            locales: [1],
            translate: name in i.name

        result = from i in Model.Ingredient,
            left_join: name in Model.IngredientNameTranslation,
            on: i.name == name.translate_id and name.locale_id in [1]

        assert inspect(query) == inspect(result)
    end

    test "translate type with list of locales" do
        query = from i in Model.Ingredient,
            locales: [1],
            translate: type in i.type

        result = from i in Model.Ingredient,
            left_join: type in Model.IngredientTypeTranslation,
            on: i.type == type.translate_id and type.locale_id in [1]

        assert inspect(query) == inspect(result)
    end

    test "translate name and type with list of locales" do
        query = from i in Model.Ingredient,
            locales: [1],
            translate: name in i.name,
            translate: type in i.type

        result = from i in Model.Ingredient,
            left_join: name in Model.IngredientNameTranslation,
            on: i.name == name.translate_id and name.locale_id in [1],
            left_join: type in Model.IngredientTypeTranslation,
            on: i.type == type.translate_id and type.locale_id in [1]

        assert inspect(query) == inspect(result)
    end

    test "translate name and type with referencing translations with list of locales" do
        query = from i in Model.Ingredient,
            locales: [1],
            translate: name in i.name,
            translate: type in i.type,
            select: { name.term, type.term }

        result = from i in Model.Ingredient,
            left_join: name in Model.IngredientNameTranslation,
            on: i.name == name.translate_id and name.locale_id in [1],
            left_join: type in Model.IngredientTypeTranslation,
            on: i.type == type.translate_id and type.locale_id in [1],
            select: { name.term, type.term }

        assert inspect(query) == inspect(result)
    end

    test "translate name and type with different list of locales" do
        query = from i in Model.Ingredient,
            locales: [1],
            translate: name in i.name,
            locales: [2],
            translate: type in i.type

        result = from i in Model.Ingredient,
            left_join: name in Model.IngredientNameTranslation,
            on: i.name == name.translate_id and name.locale_id in [1],
            left_join: type in Model.IngredientTypeTranslation,
            on: i.type == type.translate_id and type.locale_id in [2]

        assert inspect(query) == inspect(result)
    end

    test "must translate bindings" do
        locale = 1
        table = Model.Ingredient
        query = from i in table,
            locale: ^locale,
            must_translate: name in i.name

        result = from i in Model.Ingredient,
            join: name in Model.IngredientNameTranslation,
            on: i.name == name.translate_id and name.locale_id == ^locale

        assert inspect(query) == inspect(result)
    end

    test "must translate name" do
        query = from i in Model.Ingredient,
            locale: 1,
            must_translate: name in i.name

        result = from i in Model.Ingredient,
            join: name in Model.IngredientNameTranslation,
            on: i.name == name.translate_id and name.locale_id == 1

        assert inspect(query) == inspect(result)
    end

    test "must translate type" do
        query = from i in Model.Ingredient,
            locale: 1,
            must_translate: type in i.type

        result = from i in Model.Ingredient,
            join: type in Model.IngredientTypeTranslation,
            on: i.type == type.translate_id and type.locale_id == 1

        assert inspect(query) == inspect(result)
    end

    test "must translate name and type" do
        query = from i in Model.Ingredient,
            locale: 1,
            must_translate: name in i.name,
            must_translate: type in i.type

        result = from i in Model.Ingredient,
            join: name in Model.IngredientNameTranslation,
            on: i.name == name.translate_id and name.locale_id == 1,
            join: type in Model.IngredientTypeTranslation,
            on: i.type == type.translate_id and type.locale_id == 1

        assert inspect(query) == inspect(result)
    end

    test "must translate name and type with referencing translations" do
        query = from i in Model.Ingredient,
            locale: 1,
            must_translate: name in i.name,
            must_translate: type in i.type,
            select: { name.term, type.term }

        result = from i in Model.Ingredient,
            join: name in Model.IngredientNameTranslation,
            on: i.name == name.translate_id and name.locale_id == 1,
            join: type in Model.IngredientTypeTranslation,
            on: i.type == type.translate_id and type.locale_id == 1,
            select: { name.term, type.term }

        assert inspect(query) == inspect(result)
    end

    test "must translate name and type with different locales" do
        query = from i in Model.Ingredient,
            locale: 1,
            must_translate: name in i.name,
            locale: 2,
            must_translate: type in i.type

        result = from i in Model.Ingredient,
            join: name in Model.IngredientNameTranslation,
            on: i.name == name.translate_id and name.locale_id == 1,
            join: type in Model.IngredientTypeTranslation,
            on: i.type == type.translate_id and type.locale_id == 2

        assert inspect(query) == inspect(result)
    end

    test "must translate bindings with list of locales" do
        locale = [1]
        table = Model.Ingredient
        query = from i in table,
            locales: ^locale,
            must_translate: name in i.name

        result = from i in Model.Ingredient,
            join: name in Model.IngredientNameTranslation,
            on: i.name == name.translate_id and name.locale_id in ^locale

        assert inspect(query) == inspect(result)
    end

    test "must translate name with list of locales" do
        query = from i in Model.Ingredient,
            locales: [1],
            must_translate: name in i.name

        result = from i in Model.Ingredient,
            join: name in Model.IngredientNameTranslation,
            on: i.name == name.translate_id and name.locale_id in [1]

        assert inspect(query) == inspect(result)
    end

    test "must translate type with list of locales" do
        query = from i in Model.Ingredient,
            locales: [1],
            must_translate: type in i.type

        result = from i in Model.Ingredient,
            join: type in Model.IngredientTypeTranslation,
            on: i.type == type.translate_id and type.locale_id in [1]

        assert inspect(query) == inspect(result)
    end

    test "must translate name and type with list of locales" do
        query = from i in Model.Ingredient,
            locales: [1],
            must_translate: name in i.name,
            must_translate: type in i.type

        result = from i in Model.Ingredient,
            join: name in Model.IngredientNameTranslation,
            on: i.name == name.translate_id and name.locale_id in [1],
            join: type in Model.IngredientTypeTranslation,
            on: i.type == type.translate_id and type.locale_id in [1]

        assert inspect(query) == inspect(result)
    end

    test "must translate name and type with referencing translations with list of locales" do
        query = from i in Model.Ingredient,
            locales: [1],
            must_translate: name in i.name,
            must_translate: type in i.type,
            select: { name.term, type.term }

        result = from i in Model.Ingredient,
            join: name in Model.IngredientNameTranslation,
            on: i.name == name.translate_id and name.locale_id in [1],
            join: type in Model.IngredientTypeTranslation,
            on: i.type == type.translate_id and type.locale_id in [1],
            select: { name.term, type.term }

        assert inspect(query) == inspect(result)
    end

    test "must translate name and type with different list of locales" do
        query = from i in Model.Ingredient,
            locales: [1],
            must_translate: name in i.name,
            locales: [2],
            must_translate: type in i.type

        result = from i in Model.Ingredient,
            join: name in Model.IngredientNameTranslation,
            on: i.name == name.translate_id and name.locale_id in [1],
            join: type in Model.IngredientTypeTranslation,
            on: i.type == type.translate_id and type.locale_id in [2]

        assert inspect(query) == inspect(result)
    end

    test "translate name with locale enforcing same locale was applied" do
        query = from i in Model.Ingredient,
            locale: 1,
            translate: name in i.name,
            locale_match: [name]

        result = from i in Model.Ingredient,
            left_join: name in Model.IngredientNameTranslation,
            on: i.name == name.translate_id and name.locale_id == 1,
            where: name.locale_id in [1, nil]

        assert inspect(query) == inspect(result)
    end

    test "translate bindings with locale enforcing same locale was applied" do
        locale = 1
        table = Model.Ingredient
        query = from i in table,
            locale: ^locale,
            translate: name in i.name,
            locale_match: [name]

        result = from i in Model.Ingredient,
            left_join: name in Model.IngredientNameTranslation,
            on: i.name == name.translate_id and name.locale_id == ^locale,
            where: name.locale_id in [^locale, nil]

        assert inspect(query) == inspect(result)
    end

    test "translate name and type with locale enforcing same locale was applied" do
        query = from i in Model.Ingredient,
            locale: 1,
            translate: name in i.name,
            translate: type in i.type,
            locale_match: [name, type]

        result = from i in Model.Ingredient,
            left_join: name in Model.IngredientNameTranslation,
            on: i.name == name.translate_id and name.locale_id == 1,
            left_join: type in Model.IngredientTypeTranslation,
            on: i.type == type.translate_id and type.locale_id == 1,
            where: name.locale_id in [1, nil] and type.locale_id in [1, nil]

        assert inspect(query) == inspect(result)
    end

    test "translate name with list of locales enforcing same locale was applied" do
        query = from i in Model.Ingredient,
            locales: [1],
            translate: name in i.name,
            locale_match: [name]

        result = from i in Model.Ingredient,
            left_join: name in Model.IngredientNameTranslation,
            on: i.name == name.translate_id and name.locale_id in [1],
            where: name.locale_id in [1, nil]

        assert inspect(query) == inspect(result)
    end

    test "translate binding name with list of locales enforcing same locale was applied" do
        locale = [1]
        table = Model.Ingredient
        query = from i in table,
            locales: ^locale,
            translate: name in i.name,
            locale_match: [name]

        result = from i in Model.Ingredient,
            left_join: name in Model.IngredientNameTranslation,
            on: i.name == name.translate_id and name.locale_id in ^locale,
            where: [name.locale_id] in [[name.locale_id]]

        assert inspect(query) == inspect(result)
    end

    test "translate name and type with list of locales enforcing same locale was applied" do
        query = from i in Model.Ingredient,
            locales: [1],
            translate: name in i.name,
            translate: type in i.type,
            locale_match: [name, type]

        result = from i in Model.Ingredient,
            left_join: name in Model.IngredientNameTranslation,
            on: i.name == name.translate_id and name.locale_id in [1],
            left_join: type in Model.IngredientTypeTranslation,
            on: i.type == type.translate_id and type.locale_id in [1],
            where: name.locale_id in [1, nil] and type.locale_id in [1, nil]

        assert inspect(query) == inspect(result)
    end

    test "translate binding name and type with list of locales enforcing same locale was applied" do
        locale = [1]
        table = Model.Ingredient
        query = from i in table,
            locales: ^locale,
            translate: name in i.name,
            translate: type in i.type,
            locale_match: [name, type]

        result = from i in Model.Ingredient,
            left_join: name in Model.IngredientNameTranslation,
            on: i.name == name.translate_id and name.locale_id in ^locale,
            left_join: type in Model.IngredientTypeTranslation,
            on: i.type == type.translate_id and type.locale_id in ^locale,
            where: [name.locale_id, type.locale_id] in [[name.locale_id, nil], [name.locale_id, name.locale_id], [nil, type.locale_id]]

        assert inspect(query) == inspect(result)
    end

    test "translate name and type and desc with list of locales enforcing same locale was applied" do
        query = from i in Model.Ingredient,
            locales: [1],
            translate: name in i.name,
            translate: type in i.type,
            translate: desc in i.desc,
            locale_match: [name, type, desc]

        result = from i in Model.Ingredient,
            left_join: name in Model.IngredientNameTranslation,
            on: i.name == name.translate_id and name.locale_id in [1],
            left_join: type in Model.IngredientTypeTranslation,
            on: i.type == type.translate_id and type.locale_id in [1],
            left_join: desc in Model.IngredientDescTranslation,
            on: i.desc == desc.translate_id and desc.locale_id in [1],
            where: name.locale_id in [1, nil] and type.locale_id in [1, nil] and desc.locale_id in [1, nil]

        assert inspect(query) == inspect(result)
    end

    test "translate binding name and type and desc with list of locales enforcing same locale was applied" do
        locale = [1]
        table = Model.Ingredient
        query = from i in table,
            locales: ^locale,
            translate: name in i.name,
            translate: type in i.type,
            translate: desc in i.desc,
            locale_match: [name, type, desc]

        result = from i in Model.Ingredient,
            left_join: name in Model.IngredientNameTranslation,
            on: i.name == name.translate_id and name.locale_id in ^locale,
            left_join: type in Model.IngredientTypeTranslation,
            on: i.type == type.translate_id and type.locale_id in ^locale,
            left_join: desc in Model.IngredientDescTranslation,
            on: i.desc == desc.translate_id and desc.locale_id in ^locale,
            where: [name.locale_id, type.locale_id, desc.locale_id] in [
                [name.locale_id, nil, nil],
                [name.locale_id, name.locale_id, nil],
                [nil, type.locale_id, nil],
                [name.locale_id, nil, name.locale_id],
                [name.locale_id, name.locale_id, name.locale_id],
                [nil, type.locale_id, type.locale_id],
                [nil, nil, desc.locale_id]
            ]

        assert inspect(query) == inspect(result)
    end

    test "translate name and type and desc with list of different locales enforcing same locale was applied" do
        query = from i in Model.Ingredient,
            locales: [1, 2],
            translate: name in i.name,
            translate: type in i.type,
            translate: desc in i.desc,
            locale_match: [name, type, desc]

        result = from i in Model.Ingredient,
            left_join: name in Model.IngredientNameTranslation,
            on: i.name == name.translate_id and name.locale_id in [1, 2],
            left_join: type in Model.IngredientTypeTranslation,
            on: i.type == type.translate_id and type.locale_id in [1, 2],
            left_join: desc in Model.IngredientDescTranslation,
            on: i.desc == desc.translate_id and desc.locale_id in [1, 2],
            where: name.locale_id in [1, nil] and type.locale_id in [1, nil] and desc.locale_id in [1, nil] or name.locale_id in [2, nil] and type.locale_id in [2, nil] and desc.locale_id in [2, nil]

        assert inspect(query) == inspect(result)
    end

    test "translate name and type and desc with list of many different locales enforcing same locale was applied" do
        query = from i in Model.Ingredient,
            locales: [1, 2, 3],
            translate: name in i.name,
            translate: type in i.type,
            translate: desc in i.desc,
            locale_match: [name, type, desc]

        result = from i in Model.Ingredient,
            left_join: name in Model.IngredientNameTranslation,
            on: i.name == name.translate_id and name.locale_id in [1, 2, 3],
            left_join: type in Model.IngredientTypeTranslation,
            on: i.type == type.translate_id and type.locale_id in [1, 2, 3],
            left_join: desc in Model.IngredientDescTranslation,
            on: i.desc == desc.translate_id and desc.locale_id in [1, 2, 3],
            where: name.locale_id in [1, nil] and type.locale_id in [1, nil] and desc.locale_id in [1, nil] or name.locale_id in [2, nil] and type.locale_id in [2, nil] and desc.locale_id in [2, nil] or name.locale_id in [3, nil] and type.locale_id in [3, nil] and desc.locale_id in [3, nil]

        assert inspect(query) == inspect(result)
    end

    test "translate name and type and desc with list of many different locales enforcing multiple same locale was applied" do
        query = from i in Model.Ingredient,
            locales: [1, 2, 3],
            translate: name in i.name,
            translate: type in i.type,
            translate: desc in i.desc,
            locale_match: [name, type],
            locale_match: [type, desc]

        result = from i in Model.Ingredient,
            left_join: name in Model.IngredientNameTranslation,
            on: i.name == name.translate_id and name.locale_id in [1, 2, 3],
            left_join: type in Model.IngredientTypeTranslation,
            on: i.type == type.translate_id and type.locale_id in [1, 2, 3],
            left_join: desc in Model.IngredientDescTranslation,
            on: i.desc == desc.translate_id and desc.locale_id in [1, 2, 3],
            where: name.locale_id in [1, nil] and type.locale_id in [1, nil] or name.locale_id in [2, nil] and type.locale_id in [2, nil] or name.locale_id in [3, nil] and type.locale_id in [3, nil],
            where: type.locale_id in [1, nil] and desc.locale_id in [1, nil] or type.locale_id in [2, nil] and desc.locale_id in [2, nil] or type.locale_id in [3, nil] and desc.locale_id in [3, nil]

        assert inspect(query) == inspect(result)
    end

    test "translate binding name and type and desc with list of many different locales enforcing multiple same locale was applied" do
        locale = [1, 2, 3]
        table = Model.Ingredient
        query = from i in table,
            locales: ^locale,
            translate: name in i.name,
            translate: type in i.type,
            translate: desc in i.desc,
            locale_match: [name, type],
            locale_match: [type, desc]

        result = from i in Model.Ingredient,
            left_join: name in Model.IngredientNameTranslation,
            on: i.name == name.translate_id and name.locale_id in ^locale,
            left_join: type in Model.IngredientTypeTranslation,
            on: i.type == type.translate_id and type.locale_id in ^locale,
            left_join: desc in Model.IngredientDescTranslation,
            on: i.desc == desc.translate_id and desc.locale_id in ^locale,
            where: [name.locale_id, type.locale_id] in [[name.locale_id, nil], [name.locale_id, name.locale_id], [nil, type.locale_id]],
            where: [type.locale_id, desc.locale_id] in [[type.locale_id, nil], [type.locale_id, type.locale_id], [nil, desc.locale_id]]

        assert inspect(query) == inspect(result)
    end

    test "translate and match" do
        query = from i in Model.Ingredient,
            locale: 1,
            translate: name in i.name,
            where: name.term in ["foo", "bar"]

        result = from i in Model.Ingredient,
            left_join: name in Model.IngredientNameTranslation,
            on: i.name == name.translate_id and name.locale_id == 1,
            where: name.term in ["foo", "bar"]

        assert inspect(query) == inspect(result)
    end

    test "translate from join" do
        query = from t in Model.Item,
            join: i in Model.Ingredient,
            locale: 1,
            translate: name in i.name

        result = from t in Model.Item,
            join: i in Model.Ingredient,
            left_join: name in Model.IngredientNameTranslation,
            on: i.name == name.translate_id and name.locale_id == 1

        assert inspect(query) == inspect(result)
    end

    test "translate from inner_join" do
        query = from t in Model.Item,
            inner_join: i in Model.Ingredient,
            locale: 1,
            translate: name in i.name

        result = from t in Model.Item,
            inner_join: i in Model.Ingredient,
            left_join: name in Model.IngredientNameTranslation,
            on: i.name == name.translate_id and name.locale_id == 1

        assert inspect(query) == inspect(result)
    end

    test "translate from left_join" do
        query = from t in Model.Item,
            left_join: i in Model.Ingredient,
            locale: 1,
            translate: name in i.name

        result = from t in Model.Item,
            left_join: i in Model.Ingredient,
            left_join: name in Model.IngredientNameTranslation,
            on: i.name == name.translate_id and name.locale_id == 1

        assert inspect(query) == inspect(result)
    end

    test "translate from right_join" do
        query = from t in Model.Item,
            right_join: i in Model.Ingredient,
            locale: 1,
            translate: name in i.name

        result = from t in Model.Item,
            right_join: i in Model.Ingredient,
            left_join: name in Model.IngredientNameTranslation,
            on: i.name == name.translate_id and name.locale_id == 1

        assert inspect(query) == inspect(result)
    end

    test "translate from cross_join" do
        query = from t in Model.Item,
            cross_join: i in Model.Ingredient,
            locale: 1,
            translate: name in i.name

        result = from t in Model.Item,
            cross_join: i in Model.Ingredient,
            left_join: name in Model.IngredientNameTranslation,
            on: i.name == name.translate_id and name.locale_id == 1

        assert inspect(query) == inspect(result)
    end

    test "translate from full_join" do
        query = from t in Model.Item,
            full_join: i in Model.Ingredient,
            locale: 1,
            translate: name in i.name

        result = from t in Model.Item,
            full_join: i in Model.Ingredient,
            left_join: name in Model.IngredientNameTranslation,
            on: i.name == name.translate_id and name.locale_id == 1

        assert inspect(query) == inspect(result)
    end

    test "translate from inner_lateral_join" do
        query = from t in Model.Item,
            inner_lateral_join: i in Model.Ingredient,
            locale: 1,
            translate: name in i.name

        result = from t in Model.Item,
            inner_lateral_join: i in Model.Ingredient,
            left_join: name in Model.IngredientNameTranslation,
            on: i.name == name.translate_id and name.locale_id == 1

        assert inspect(query) == inspect(result)
    end

    test "translate from left_lateral_join" do
        query = from t in Model.Item,
            left_lateral_join: i in Model.Ingredient,
            locale: 1,
            translate: name in i.name

        result = from t in Model.Item,
            left_lateral_join: i in Model.Ingredient,
            left_join: name in Model.IngredientNameTranslation,
            on: i.name == name.translate_id and name.locale_id == 1

        assert inspect(query) == inspect(result)
    end
end
