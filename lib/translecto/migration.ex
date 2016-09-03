defmodule Translecto.Migration do
    import Ecto.Migration
    @moduledoc """
      Provides convenient functionality for creating tables that support translatable
      data.
    """

    @doc """
      Setup the table as a translation lookup. All fields in this table will now be
      translatable.

      Translation groups (groups of equivalent data) are specified using the
      `:translate_id` field. While the different translations for those individual
      groups is specified using the `:locale_id`, which will be of the type specified
      by the config or in the options argument under the `:locale` key. The following variants are:

        \# Adds a FK reference from :locale_id to the specified table. Optionally passing in
        \# any options specified.
        { :table, name }
        { :table, name, options }

        \# Adds a field of the specified type for the :locale_id field. Optionally passing in
        \# any options specified.
        { :type, type }
        { :type, type, options }

      Unless overriden in the options, the table should have its default primary key
      set to false. While the new `:translate_id` and `:locale_id` fields become the
      composite primary keys.

        create table(:ingredient_name_translations, primary_key: false) do
            translation
            add :term, :string, null: false
        end

        create table(:item_translations, primary_key: false) do
            translation locale: { :type, :char, [size: 2, null: false] }
            add :name, :string, null: false
            add :description, :string, null: false
        end
    """
    @spec translation(keyword()) :: no_return
    def translation(opts \\ []) do
        { locale, opts } = if opts[:locale] do
            { opts[:locale], Keyword.delete(opts, :locale) }
        else
            { Application.fetch_env!(:translecto, :locale)[:db], opts }
        end

        add :translate_id, :serial,
            Keyword.merge([
                primary_key: true,
                # comment: "The translation group for this entry"
            ], opts)

        { type, opts } = case locale do
            { :table, table } -> { references(table), opts }
            { :table, table, options } -> { references(table, options), opts }
            { :type, type } -> { type, opts }
            { :type, type, options } -> { type, Keyword.merge(options, opts) }
        end

        add :locale_id, type,
            Keyword.merge([
                primary_key: true,
                # comment: "The language locale for this entry"
            ], opts)
    end

    @doc """
      Add a translatable field to a given table.

      This indicates that the field should be translated to access its contents. That
      it is a reference to a translation table.

        create table(:ingredients) do
            translate :name, null: false
        end
    """
    @spec translate(atom, keyword()) :: no_return
    def translate(column, opts \\ []) do
        add column, :id, opts
    end
end
