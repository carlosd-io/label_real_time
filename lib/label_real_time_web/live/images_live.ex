defmodule LabelRealTimeWeb.ImagesLive do
  use LabelRealTimeWeb, :live_view

  alias LabelRealTime.Images
  alias LabelRealTime.Images.Image

  def mount(_params, _session, socket) do
    if connected?(socket), do: Images.subscribe()

    socket =
      assign(socket,
        form: to_form(Images.change_image(%Image{}))
      )

    socket =
      allow_upload(
        socket,
        :photos,
        accept: ~w(.png .jpeg .jpg),
        max_entries: 3,
        max_file_size: 10_000_000
      )

    {:ok, stream(socket, :images, Images.list_images())}
  end

  def handle_event("cancel", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :photos, ref)}
  end

  def handle_event("validate", %{"image" => params}, socket) do
    changeset =
      %Image{}
      |> Images.change_image(params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"image" => params}, socket) do
    # copy temp file to priv/static/uploads/photoname-1.png
    # URL path: /uploads/photoname-1.png
    # Notice that the Plug.Static plug in endpoint.ex is not configured to get the
    # uploads folder to serve images. I had to add uploads to the
    # static_paths() function in label_real_time_web.ex

    image_locations =
      consume_uploaded_entries(socket, :photos, fn meta, entry ->
        dest =
          Path.join([
            "priv",
            "static",
            "uploads",
            "#{entry.uuid}-#{entry.client_name}"
          ])

        File.mkdir_p!(Path.dirname(dest))

        File.cp!(meta.path, dest)

        url_path = static_path(socket, "/uploads/#{Path.basename(dest)}")

        {:ok, url_path}
      end)

    params = Map.put(params, "image_locations", image_locations)

    case Images.create_image(params) do
      {:ok, _image} ->
        changeset = Images.change_image(%Image{})
        {:noreply, assign_form(socket, changeset)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  def handle_info({:image_created, image}, socket) do
    {:noreply, stream_insert(socket, :images, image, at: 0)}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end
end
