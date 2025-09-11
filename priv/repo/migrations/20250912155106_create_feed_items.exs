defmodule Repo.Migrations.CreateFeedItems do
  use Ecto.Migration

  def change do
    create table(:feed_items) do
      add :title, :string
      add :link, :string
      add :description, :text
      add :categories, {:array, :string}
      add :published, :utc_datetime

      timestamps()
    end

    create unique_index(:feed_items, [:link])
  end
end
