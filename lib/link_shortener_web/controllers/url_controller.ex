defmodule LinkShortenerWeb.UrlController do
  use LinkShortenerWeb, :controller
  alias LinkShortener.Url
  import Ecto.Query

  def create(conn, %{"url_data" => url_data}) do
    data =
      url_data["image"]
      |> case do
        nil ->
          url_data

        img ->
          Map.merge(url_data, %{
            "image" => File.read!(img.path) |> Base.encode64(),
            "image_type" => img.content_type,
            "image_name" => img.filename
          })
      end

    %Url{}
    |> LinkShortener.Url.changeset(data)
    |> LinkShortener.Repo.insert()
    |> case do
      {:ok, _url} ->
        changeset = LinkShortener.Url.changeset(%LinkShortener.Url{})

        conn
        |> put_flash(:info, "Link created successfully")
        |> render("new.html", changeset: changeset)

      {:error, %Ecto.Changeset{} = changeset} ->
        errors =
          Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
            Enum.reduce(opts, msg, fn {key, value}, acc ->
              String.replace(acc, "%{#{key}}", to_string(value))
            end)
          end)
          |> Enum.map_join(" ", fn {key, val} -> ~s{"#{key}", "#{val}"} end)

        conn
        |> put_status(:bad_request)
        |> put_flash(:error, errors)
        |> render("new.html", changeset: changeset)
    end
  end

  def new(conn, _params) do
    changeset = LinkShortener.Url.changeset(%LinkShortener.Url{})
    render(conn, "new.html", changeset: changeset)
  end

  def show(conn, %{"url_name" => url_name}) do
    Url
    |> where([u], u.url_name == ^url_name)
    |> order_by([u], desc: u.id)
    |> limit([u], 1)
    |> LinkShortener.Repo.one()
    |> case do
      nil ->
        conn
        |> put_status(:not_found)
        |> put_view(HelloWeb.ErrorView)
        |> render(:"404")

      url ->
        meta_image =
          url.image
          |> case do
            nil ->
              nil

            _img ->
              %{property: "og:image", content: "#{LinkShortenerWeb.Router.Helpers.url(conn)}/img/#{url.image_name}"}
          end

        meta_attrs = [
          %{name: "og:type", content: "website"},
          %{name: "og:description", content: url.description},
          %{name: "og:title", content: url.title},
          meta_image
        ]

        # <!-- Primary Meta Tags -->
        # <title>Meta Tags — Preview, Edit and Generate</title>
        # <meta name="title" content="Meta Tags — Preview, Edit and Generate">
        # <meta name="description" content="With Meta Tags you can edit and experiment with your content then preview how your webpage will look on Google, Facebook, Twitter and more!">

        # <!-- Open Graph / Facebook -->
        # <meta property="og:type" content="website">
        # <meta property="og:url" content="https://metatags.io/">
        # <meta property="og:title" content="Meta Tags — Preview, Edit and Generate">
        # <meta property="og:description" content="With Meta Tags you can edit and experiment with your content then preview how your webpage will look on Google, Facebook, Twitter and more!">
        # <meta property="og:image" content="https://metatags.io/assets/meta-tags-16a33a6a8531e519cc0936fbba0ad904e52d35f34a46c97a2c9f6f7dd7d336f2.png">

        # <!-- Twitter -->
        # <meta property="twitter:card" content="summary_large_image">
        # <meta property="twitter:url" content="https://metatags.io/">
        # <meta property="twitter:title" content="Meta Tags — Preview, Edit and Generate">
        # <meta property="twitter:description" content="With Meta Tags you can edit and experiment with your content then preview how your webpage will look on Google, Facebook, Twitter and more!">
        # <meta property="twitter:image" content="https://metatags.io/assets/meta-tags-16a33a6a8531e519cc0936fbba0ad904e52d35f34a46c97a2c9f6f7dd7d336f2.png">
        conn
        |> render("show.html", meta_attrs: meta_attrs, url: url)

        # |> redirect(external: url.url)
    end
  end

  def show(conn, %{"img_name" => img_name}) do
    Url
    |> where([u], u.image_name == ^img_name)
    |> order_by([u], desc: u.id)
    |> limit([u], 1)
    |> LinkShortener.Repo.one()
    |> case do
      nil ->
        conn
        |> render(LinkShortenerWeb.ErrorView)

      url ->
        {:ok, image} =
          url.image
          |> Base.decode64()

        conn
        |> put_resp_content_type(url.image_type)
        |> send_resp(200, image)
    end
  end
end
