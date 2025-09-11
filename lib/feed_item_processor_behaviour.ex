defmodule FeedItemProcessorBehaviour do
  @callback process_one(String.t()) :: {:ok, list()} | {:error, any()}
end
