defmodule JSONAPI.View do
  @moduledoc """
  A View is simply a module that defines certain callbacks to configure proper
  rendering of your JSONAPI documents.

      defmodule PostView do
        use JSONAPI.View

        def fields, do: [:id, :text, :body]
        def type, do: "post"
        def relationships do
          [author: UserView,
           comments: CommentView]
        end
      end

      defmodule UserView do
        use JSONAPI.View

        def fields, do: [:id, :username]
        def type, do: "user"
        def relationships, do: []
      end

      defmodule CommentView do
        use JSONAPI.View

        def fields, do: [:id, :text]
        def type, do: "comment"
        def relationships do
          [user: {UserView, :include}]
        end
      end

  You can now call `UserView.show(user, conn, conn.params)` and it will render
  a valid jsonapi doc.

  ## Fields

  By default, the resulting JSON document consists of fields, defined in fields/0
  function. You can define custom fields or override current fields by defining
  inside the view function `field_name/2` that takes data and conn as arguments.

      defmodule UserView do
        use JSONAPI.View

        def fullname(data, conn), do: "fullname"

        def fields, do: [:id, :username, :fullname]
        def type, do: "user"
        def relationships, do: []
      end

  ## Relationships

  Currently the relationships callback expects that a map is returned
  configuring the information you will need. If you have the following Ecto
  Model setup

      defmodule User do
        schema "users" do
          field :username
          has_many :posts
          has_one :image
        end
      end

  and the includes setup from above. If your Post has loaded the author and the
  query asks for it then it will be loaded.

  So for example:
  `GET /posts?include=post.author` if the author record is loaded on the Post, and you are using
  the `JSONAPI.QueryParser` it will be included in the `includes` section of the JSONAPI document.

  If you always want to include a relationship. First make sure its always preloaded
  and then use the `[user: {UserView, :include}]` syntax in your `includes` function. This tells
  the serializer to *always* include if its loaded.

  ## Options
    * `:host` (binary) - Allows the `host` to be overrided for generated URLs.  Defaults to `host` of the supplied `conn`.

    * `:scheme` (atom) - Enables configuration of the HTTP scheme for generated URLS.  Defaults to `scheme` from the provided `conn`.

    * `:underscore_to_dash` (boolean) - Use dash (`-`) as the word separated for JSON in place of underscore (`_`) per the JSONAPI spec [recommendations](http://jsonapi.org/recommendations/).  Defaults to `false`.

  The default behaviour for `host` and `scheme` is to derive it from the `conn` provided, while the
  default style for presentation in names is to be underscored and not dashed.
  """
  defmacro __using__(opts \\ []) do
    {type, opts} = Keyword.pop(opts, :type)
    {namespace, _opts} = Keyword.pop(opts, :namespace, "")

    quote do
      import JSONAPI.Serializer, only: [serialize: 4]

      @resource_type unquote(type)
      @namespace unquote(namespace)

      def id(nil), do: nil
      def id(%{__struct__: Ecto.Association.NotLoaded}), do: nil
      def id(%{id: id}), do: to_string(id)

      if @resource_type do
        def type, do: @resource_type
      else
        def type, do: raise("Need to implement type/0")
      end

      def attributes(data, conn) do
        hidden =
          if Enum.member?(__MODULE__.__info__(:functions), {:hidden, 0}) do
            Deprecation.warn(:hidden)
            __MODULE__.hidden()
          else
            hidden(data)
          end

        visible_fields = fields() -- hidden

        Enum.reduce(visible_fields, %{}, fn field, intermediate_map ->
          value =
            case function_exported?(__MODULE__, field, 2) do
              true -> apply(__MODULE__, field, [data, conn])
              false -> Map.get(data, field)
            end

          Map.put(intermediate_map, field, value)
        end)
      end

      def links(_data, _conn), do: %{}

      def meta(_data, _conn), do: nil

      def relationships, do: []

      def fields, do: raise("Need to implement fields/0")

      def hidden(data), do: []

      def show(model, conn, _params, meta \\ nil), do: serialize(__MODULE__, model, conn, meta)
      def index(models, conn, _params, meta \\ nil), do: serialize(__MODULE__, models, conn, meta)

      def url_for(nil, nil) do
        "#{@namespace}/#{type()}"
      end

      def url_for(data, nil) when is_list(data) do
        "#{@namespace}/#{type()}"
      end

      def url_for(data, nil) do
        "#{@namespace}/#{type()}/#{id(data)}"
      end

      def url_for(data, %Plug.Conn{} = conn) when is_list(data) do
        "#{scheme(conn)}://#{host(conn)}#{@namespace}/#{type()}"
      end

      def url_for(data, %Plug.Conn{} = conn) do
        "#{scheme(conn)}://#{host(conn)}#{@namespace}/#{type()}/#{id(data)}"
      end

      def url_for_rel(data, rel_type, conn) do
        "#{url_for(data, conn)}/relationships/#{rel_type}"
      end

      def url_for_pagination(data, conn, pagination_attrs) do
        pagination_attrs
        |> Enum.reduce(%{}, fn {key, value}, acc ->
          Map.put(acc, "page[#{key}]", value)
        end)
        |> URI.encode_query()
        |> prepare_url(data, conn)
      end

      defp prepare_url("", data, conn), do: url_for(data, conn)

      defp prepare_url(query, data, conn) do
        "#{url_for(data, conn)}?#{query}"
      end

      if Code.ensure_loaded?(Phoenix) do
        def render("show.json", %{data: data, conn: conn, params: params, meta: meta}),
          do: show(data, conn, params, meta: meta)

        def render("show.json", %{data: data, conn: conn, meta: meta}),
          do: show(data, conn, conn.params, meta: meta)

        def render("show.json", %{data: data, conn: conn}), do: show(data, conn, conn.params)

        def render("index.json", %{data: data, conn: conn, params: params, meta: meta}),
          do: index(data, conn, params, meta)

        def render("index.json", %{data: data, conn: conn, meta: meta}),
          do: index(data, conn, conn.params, meta)

        def render("index.json", %{data: data, conn: conn}), do: index(data, conn, conn.params)
      end

      defp host(conn), do: Application.get_env(:jsonapi, :host, conn.host)

      defp scheme(conn), do: Application.get_env(:jsonapi, :scheme, to_string(conn.scheme))

      defoverridable attributes: 2,
                     links: 2,
                     fields: 0,
                     hidden: 1,
                     id: 1,
                     meta: 2,
                     relationships: 0,
                     type: 0,
                     url_for: 2,
                     url_for_rel: 3
    end
  end
end
