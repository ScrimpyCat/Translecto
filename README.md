# Translecto

Translecto is a minimal translation library for Ecto to allow for translations at the database level.

It takes a fairly simplistic approach to supporting this. The general idea is that your model has fields that it wishes to be translatable, these fields reference translation models (or model) which contain the translatable terms grouped by `:translate_id` and `:locale_id`.

The `:translate_id` is the logical grouping of translatable data. While the `:locale_id` is the value (FK, string, integer, etc.) that distinguishes the specific translation for the given locale.

Locale
------

The locale is used to specify a specific localised translation. A locale may be a model which contains the different locales, or it may be another type that will be stored with the translation itself. Locales can apply globally or they may be different per translation. A globally applied locale can be specified in the config file by doing the following:

```elixir
config :translecto,
    locale: [schema: { :model, Model.Locale }, db: { :table, :locales }]
```

The `:schema` field indicates the locale type that is applied to schemas, while the `:db` field indicates the locale type that is applied to the database (migration) files. For more info on the type of input see `Translecto.Schema.Translation.translation/1` and `Translecto.Migration.translation/1`.

Translations
------------

A translation is the model representing translated data. Multiple models may be used to store translations (possibly per context) or a single model can be used. To create a translation model you create a translation table and schema accordingly.

```elixir
defmodule Repo.Migrations.CreateItem.Content.Translations do
    use Ecto.Migration
    import Translecto.Migration

    def change do
        create table(:item_content_translations, primary_key: false) do
            translation

            add :name, :string,
                null: false

            add :description, :string,
                null: false

            timestamps
        end
    end
end

defmodule Item.Content.Translation do
    use Ecto.Schema
    use Translecto.Schema.Translation

    schema "food_diet_list" do
        translation
        field :name, :string
        field :description, :string
        timestamps
    end

    def changeset(struct, params \\ %{}) do
        struct
        |> translation_changeset(params)
        |> cast(params, [:name, :description])
        |> validate_required([:name, :description])
    end
end
```

Translatables
-------------

A translatable is a field that has translatable data. It references a group of rows from a translation model (by `:translate_id`), only needing the `:locale_id` to indicate the relevant localisation.

```elixir
defmodule Repo.Migrations.CreateItem do
    use Ecto.Migration
    import Translecto.Migration

    def change do
        create table(:items) do
            translate :content,
                null: false

            # ... other fields

            timestamps
        end
    end
end

defmodule Item do
    use Ecto.Schema
    use Translecto.Schema.Translatable

    schema "items" do
        translatable :content, Item.Content.Translation
        # ... other fields
        timestamps
    end

    def changeset(struct, params \\ %{}) do
        struct
        |> translatable_changeset(params, [:content])
        |> validate_required([:content])
        # |> constraints/validations for other fields
    end
end
```

Insertion
---------

To insert stuff you simply insert the translation data into the translation model using the correct grouping (`:translate_id`, `:locale_id`).

```elixir
content = Repo.insert! Item.Content.Translation.changeset(%Item.Content.Translation{}, %{ locale_id: 1, name: "1_1_name", description: "1_1_desc" })
Repo.insert! Item.Content.Translation.changeset(%Item.Content.Translation{}, %{ translate_id: content.translate_id, locale_id: 2, name: "1_2_name", description: "1_2_desc" })

Repo.insert! Item.changeset(%Item{}, %{ content: content.translate_id })
```

Querying
--------

To simplify querying of translatable fields, the from query syntax has been extended to introduce a `:locale` field, and a `:translate` field. The `:locale` field specifies the current `:locale_id`, while the `:translate` field maps a model's translatable field to a new name.

```elixir
from item in Item,
    locale: 1,
    translate: content in item.content,
    select: { content.name, content.description }
```
