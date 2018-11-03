use Mix.Config

import_config "simple_markdown_rules.exs"

config :ex_doc, :markdown_processor, ExDocSimpleMarkdown
