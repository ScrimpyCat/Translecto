defmodule Translecto.Schema.Translation do
    import Ecto.Schema
    @moduledoc """
      Sets up a translation schema.

      This module coincides with the migration function `Translecto.Migration.translation/1`.
      To correctly use this module a schema should call `use Translecto.Schema.Translation`,
      overriding the default primary_key behaviour if needed and then adding the `translation/1`
      macro to the schema.
    """

    defmacro __using__(options) do
        pkey = if Keyword.get(options, :primary_key, true) do
            quote do: @primary_key { :translate_id, :id, autogenerate: true }
        end

        quote do
            import Translecto.Schema.Translation
            import Translecto.Changeset

            unquote(pkey)
        end
    end

    @doc """
      Setup the schema as a translation.

      It refers to the `:translecto` config's `:locale` field to get the default type information.
      Alternativaly this type information may be passed in through the options argument under the
      `:locale` key. The following variants are:

        \# Declares a belong_to for the :locale field, referencing the model module. Optionally
        \# passing in any options specified.
        { :model, module }
        { :model, module, options }

        \# Declares a field of the specified type for the :locale_id field. Optionally passing in
        \# any options specified.
        { :type, type }
        { :type, type, options }

      An example translation schema:

        defmodule Ingredient.Translation do
            use Translecto.Schema.Translation

            schema "ingredient_translations" do
                translation
                field :term, :string
            end

            def changeset(struct, params \\\\ %{}) do
                struct
                |> translation_changeset(params)
                |> cast(params, [:term])
                |> validate_required([:term])
            end
        end

        defmodule Item.Translation do
            use Translecto.Schema.Translation

            schema "item_translations" do
                translation locale: { :type, :string }
                field :name, :string
                field :description, :string
            end

            def changeset(struct, params \\\\ %{}) do
                struct
                |> translation_changeset(params)
                |> cast(params, [:name, :description])
                |> validate_required([:name, :description])
            end
        end
    """
    defmacro translation(opts \\ []) do
        case if(opts[:locale], do: opts[:locale], else: Application.fetch_env!(:translecto, :locale)[:schema]) do
            { :model, model } -> quote do: belongs_to :locale, unquote(model)
            { :model, model, options } -> quote do: belongs_to :locale, unquote(model), unquote(options)
            { :type, type } -> quote do: field :locale_id, unquote(type)
            { :type, type, options } -> quote do: field :locale_id, unquote(type), unquote(options)
        end
    end
end
