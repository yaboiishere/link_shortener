defmodule LinkShortener.Repo.Migrations.CreateUrls do
  use Ecto.Migration

  def change do
    create table(:urls) do
      add :url_name, :string
      add :url, :string
      add :image, :string
      add :title, :string
      add :description, :string

      timestamps()
    end
    create unique_index(:urls, [:url_name])

  end
end
