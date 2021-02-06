defmodule LinkShortener.Url do
  use Ecto.Schema
  import Ecto.Changeset

  schema "urls" do
    field :description, :string
    field :image, :string
    field :title, :string
    field :url, :string
    field :url_name, :string
    field :image_type, :string
    field :image_name, :string

    timestamps()
  end

  @doc false
  def changeset(url, attrs \\ %{}) do
    url
    |> cast(attrs, [:url_name, :url, :image, :title, :description, :image_type, :image_name])
    |> validate_required([:url_name, :url])
    |> unique_constraint(:url_name)
  end
end
