defmodule Translecto.Query do
    @moduledoc """
      Provides convenient functionality for querying translatable models.
    """
    defmacro __using__(_options) do
        quote do
            import Translecto.Query
            import Ecto.Query, except: [from: 1, from: 2]
        end
    end

    defp get_table({ :in, _, [{ ref, _, _ }, data] }), do: { ref, data }

    defp expand_translate_query(kw, tables, locale \\ 1), do: Enum.reverse(expand_translate_query(kw, tables, locale, []))

    defp expand_translate_query([], _, _, acc), do: acc
    defp expand_translate_query([{ :translate, { :in, _, [name, { { :., _, [table_name = { table, _, _ }, field] }, _, _ }] } }|kw], tables, locale = { :locale, locale_id }, acc) do
        expand_translate_query(kw, tables, locale, [quote do
            { :on, unquote(table_name).unquote(field) == unquote(name).translate_id and unquote(name).locale_id == unquote(locale_id) }
        end, quote do
            { :left_join, unquote(name) in ^unquote(tables[table]).get_translation(unquote(field)) }
        end|acc])
    end
    defp expand_translate_query([{ :translate, { :in, _, [name, { { :., _, [table_name = { table, _, _ }, field] }, _, _ }] } }|kw], tables, locale = { :locales, locale_ids }, acc) do
        expand_translate_query(kw, tables, locale, [quote do
            { :on, unquote(table_name).unquote(field) == unquote(name).translate_id and unquote(name).locale_id in unquote(locale_ids) }
        end, quote do
            { :left_join, unquote(name) in ^unquote(tables[table]).get_translation(unquote(field)) }
        end|acc])
    end
    defp expand_translate_query([{ :must_translate, { :in, _, [name, { { :., _, [table_name = { table, _, _ }, field] }, _, _ }] } }|kw], tables, locale = { :locale, locale_id }, acc) do
        expand_translate_query(kw, tables, locale, [quote do
            { :on, unquote(table_name).unquote(field) == unquote(name).translate_id and unquote(name).locale_id == unquote(locale_id) }
        end, quote do
            { :join, unquote(name) in ^unquote(tables[table]).get_translation(unquote(field)) }
        end|acc])
    end
    defp expand_translate_query([{ :must_translate, { :in, _, [name, { { :., _, [table_name = { table, _, _ }, field] }, _, _ }] } }|kw], tables, locale = { :locales, locale_ids }, acc) do
        expand_translate_query(kw, tables, locale, [quote do
            { :on, unquote(table_name).unquote(field) == unquote(name).translate_id and unquote(name).locale_id in unquote(locale_ids) }
        end, quote do
            { :join, unquote(name) in ^unquote(tables[table]).get_translation(unquote(field)) }
        end|acc])
    end
    defp expand_translate_query([expr = { :join, table }|kw], tables, locale, acc) do
        expand_translate_query(kw, [get_table(table)|tables], locale, [expr|acc])
    end
    defp expand_translate_query([{ :locale_match, translations }|kw], tables, locale = { :locale, locale_id }, acc) do
        expand_translate_query(kw, tables, locale, build_locale_matcher(translations, [locale_id], acc))
    end
    defp expand_translate_query([{ :locale_match, translations }|kw], tables, locale = { :locales, locale_ids }, acc) do
        expand_translate_query(kw, tables, locale, build_locale_matcher(translations, locale_ids, acc))
    end
    defp expand_translate_query([locale = { :locale, _ }|kw], tables, _, acc), do: expand_translate_query(kw, tables, locale, acc)
    defp expand_translate_query([locale = { :locales, _ }|kw], tables, _, acc), do: expand_translate_query(kw, tables, locale, acc)
    defp expand_translate_query([expr|kw], tables, locale, acc), do: expand_translate_query(kw, tables, locale, [expr|acc])

    defp build_locale_matcher(tables, locales, acc) do
        [{ :where, Enum.map(locales, fn locale ->
            Enum.map(tables, fn table ->
                quote do
                    unquote(table).locale_id in [unquote(locale), nil]
                end
            end)
            |> Enum.chunk_every(2)
            |> Enum.map(fn
                [match] -> match
                matches -> { :and, [], matches }
            end)
            |> Enum.reduce(fn match, acc ->
                { :and, [], [acc, match]}
            end)
        end)
        |> Enum.chunk_every(2)
        |> Enum.map(fn
            [match] -> match
            matches -> { :or, [], matches }
        end)
        |> Enum.reduce(fn match, acc ->
            { :or, [], [acc, match]}
        end) }|acc]
    end

    @doc """
      Create a query.

      It allows for the standard [`Ecto.Query.from/2`](https://hexdocs.pm/ecto/Ecto.Query.html#from/2)
      query syntax and functionality to be used. But adds support for some new expressions aimed at
      simplifying the creation of translatable queries. Such as `locale`, `locales`, `translate`,
      `must_translate`, `locale_match`.

      A translatable query is structured as follows:

        \# Get the english names for all ingredients.
        from ingredient in Model.Ingredient,
            locale: ^en.id,
            translate: name in ingredient.name,
            select: name.term

        \# Get only the ingredients which have english names.
        from ingredient in Model.Ingredient,
            locale: ^en.id,
            must_translate: name in ingredient.name,
            select: name.term

        \# Get the english and french names for all ingredients.
        from ingredient in Model.Ingredient,
            locales: ^[en.id, fr.id],
            translate: name in ingredient.name,
            select: name.term

        \# Get the english and french names and types for all ingredients (results won't have mixed locales)
        from ingredient in Model.Ingredient,
            locales: ^[en.id, fr.id],
            translate: info in ingredient.info,
            select: { info.name, info.type }

        \# Get the english and french names and types for all ingredients (results may have mixed locales)
        from ingredient in Model.Ingredient,
            locales: ^[en.id, fr.id],
            translate: name in ingredient.name,
            translate: type in ingredient.type,
            select: { name.term, type.term }

        \# Get the english and french names and types for all ingredients (results won't have mixed locales)
        from ingredient in Model.Ingredient,
            locales: ^[en.id, fr.id],
            translate: name in ingredient.name,
            translate: type in ingredient.type,
            locale_match: [name, type],
            select: { name.term, type.term }

      A translatable query requires a locale to be set using the `:locale` keyword. This value should be
      the locale value that will be matched in the translation model's for `:locale_id` field. Alternatively
      a list of locales can be matched against using the keyword `:locales`, where a list of locale values
      is provided.

      The `:translate` keyword is used to create access to any translatable terms, if those terms are not
      available it will return null instead. While `:must_translate` is an alternative keyword that enforces
      a translation exists. These take the form of an `in` expression where the left argument is the named
      reference to that translation, and the right argument is the translatable field (field marked as
      `Translecto.Schema.Translatable.translatable/3`).

      After using translate the translatable term(s) for that field are now available throughout the query,
      in the given locale specified.

        \# Get the ingredient whose english name matches "orange"
        from ingredient in Model.Ingredient,
            locale: ^en.id,
            translate: name in ingredient.name, where: name.term == "orange",
            select: ingredient

      Multiple translates can be used together in the same expression to translate as many fields of
      the translatable fields as needed.

      The `:locale_match` keyword is used to enforce the specified translatable fields are all of the
      same locale (if the field was successfully retrieved). This keyword takes a list of translatable
      fields.
    """
    @spec from(any, keyword()) :: Macro.t
    defmacro from(expr, kw \\ []) do
        quote do
            Ecto.Query.from(unquote(expr), unquote(expand_translate_query(kw, [get_table(expr)])))
        end
    end
end
