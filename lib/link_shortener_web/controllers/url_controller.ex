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
        |> render("new.html", changeset: changeset, meta_attrs: [])

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
        |> render("new.html", changeset: changeset, meta_attrs: [])
    end
  end

  def new(conn, _params) do
    changeset = LinkShortener.Url.changeset(%LinkShortener.Url{})
    render(conn, "new.html", changeset: changeset, meta_attrs: [])
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
        # meta_image =
        #   url.image
        #   |> case do
        #     nil ->
        #       nil

        #     _img ->
        #       nil
        #   end

        meta_attrs = [
          %{name: "og:type", content: "website"},
          %{name: "og:title", content: url.title},
          %{name: "og:description", content: url.description},
          %{
            property: "og:image",
            content: "#{LinkShortenerWeb.Router.Helpers.url(conn)}/img/#{url.image_name}"
          },
          %{name: "twitter:title", content: url.title},
          %{name: "twitter:description", content: url.description},
          %{
            property: "twitter:image",
            content: "#{LinkShortenerWeb.Router.Helpers.url(conn)}/img/#{url.image_name}"
          }
        ]

        # <!-- Primary Meta Tags -->
        # <title>asdasd</title>
        # <meta name="title" content="asdasd">
        # <meta name="description" content="asdasdasdasdasdasdasd">

        # <!-- Open Graph / Facebook -->
        # <meta property="og:type" content="website">
        # <meta property="og:url" content="https://lshrtn.herokuapp.com/img">
        # <meta property="og:title" content="asdasd">
        # <meta property="og:description" content="asdasdasdasdasdasdasd">
        # <meta property="og:image" content="http://example.com/img/photo_2020-03-06_19-02-40.jpg">

        # <!-- Twitter -->
        # <meta property="twitter:card" content="summary_large_image">
        # <meta property="twitter:url" content="https://lshrtn.herokuapp.com/img">
        # <meta property="twitter:title" content="asdasd">
        # <meta property="twitter:description" content="asdasdasdasdasdasdasd">
        # <meta property="twitter:image" content="http://example.com/img/photo_2020-03-06_19-02-40.jpg">
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
