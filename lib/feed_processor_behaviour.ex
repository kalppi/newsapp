defmodule FeedProcessorBehaviour do
  @moduledoc """
    Behaviour for processing feeds.

    The `repository_module` argument must be a module implementing the FeedRepositoryBehaviour.
  """

  @doc """
    Processes feeds from the given repository module.

    ## Parameters

    - repository_module: A module implementing FeedRepositoryBehaviour.

    ## Returns

    - :ok on success
    - {:error, reason} on failure
  """

  @callback process_feeds(module()) :: :ok
  @callback process_one(String.t()) :: {:ok, list()} | {:error, any()}
end
