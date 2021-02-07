defmodule LinkShortenerWeb.Router do
  use LinkShortenerWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", LinkShortenerWeb do
    pipe_through :browser

    get "/", UrlController, :new
    resources "/", UrlController, only: [:create]
    get "/img/:img_name", UrlController, :show
    get "/:url_name", UrlController, :show
  end
end
