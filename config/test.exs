use Mix.Config

config :translecto,
    locale: [schema: { :model, TranslectoTest.Model.Locale }, db: { :table, :locales }]
