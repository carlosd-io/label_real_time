defmodule LabelRealTimeWeb.LabellingLive do
  use LabelRealTimeWeb, :live_view

  alias LabelRealTime.Images
  alias LabelRealTimeWeb.Presence
  alias LabelRealTime.CircleDrawer
  alias LabelRealTime.Subimages.Subimage
  alias LabelRealTime.Subimages
  import LabelRealTime.Colors

  @topic "cursorview"

  def mount(_params, _session, socket) do
    # Get all images from DB
    images_records = Images.list_images()
    # Make a list of images from records
    images =
      images_records
      |> Enum.map(fn image -> image.image_locations end)
      |> List.flatten()

    # Get name field of images record
    images_dataset_name =
      images_records
      |> Enum.map(fn image -> image.name end)
      |> List.flatten()
      |> hd()

    # Get date timestamp from images record
    d =
      images_records
      |> Enum.map(fn image -> image.inserted_at end)
      |> List.flatten()
      |> hd()

    image_time_stamp = "#{d.year}-#{d.month}-#{d.day}-#{d.hour}-#{d.minute}-#{d.second}"
    IO.inspect(image_time_stamp, label: "IMAGE_TIME_STAMP:")

    # Get all subimages from DB, create changeset, and create form
    # subimages = Subimages.list_subimages()
    subimage_changeset = Subimages.change_subimage(%Subimage{})
    subimage_form = to_form(subimage_changeset)

    # img =
    #   0..18
    #   |> Enum.map(&String.pad_leading("#{&1}", 2, "0"))
    #   |> Enum.map(&"juggling-#{&1}.jpg")

    # IO.inspect(images)
    # IO.inspect(socket.assigns)

    # Get logged-in user from assigns and
    # obtain username and its color from email
    %{current_user: current_user} = socket.assigns
    username = current_user.email |> String.split("@") |> hd()
    color = make_HSL_color(current_user.email)

    # When liveview is connected, declare presences
    if connected?(socket) do
      {:ok, _reference} =
        Presence.track(self(), @topic, socket.id, %{
          socket_id: socket.id,
          x: 50,
          y: 50,
          message: "",
          username: username,
          color: color,
          canvas: CircleDrawer.new_canvas()
        })
    end

    Phoenix.PubSub.subscribe(LabelRealTime.PubSub, @topic)

    # List of presences
    presences =
      Presence.list(@topic)
      |> Enum.map(fn {_, data} -> data[:metas] |> List.first() end)

    socket =
      socket
      |> assign(:images, images)
      |> assign(:image_time_stamp, image_time_stamp)
      |> assign(:images_dataset_name, images_dataset_name)
      |> assign(:subimage_form, subimage_form)
      |> assign(:current, 0)
      |> assign(:is_playing, false)
      |> assign(:timer, nil)
      |> assign(:username, username)
      |> assign(:presences, presences)
      |> assign(:socket_id, socket.id)
      |> assign(:canvas, CircleDrawer.new_canvas())

    {:ok, socket}
  end

  def handle_event("save-image", %{"subimage" => subimage_params}, socket) do
    # Inspect socket
    # IO.inspect(socket, label: "socket values")

    # subimage_params should be something like: %{"label" => "Label 1"}
    IO.inspect(subimage_params, label: "SUBIMAGE PARAMS:")

    # Get X and Y coordinates from two circles drawn
    my_x1 = Enum.at(socket.assigns.canvas.circles, 1).x |> trunc()
    my_y1 = Enum.at(socket.assigns.canvas.circles, 1).y |> trunc()
    my_x2 = Enum.at(socket.assigns.canvas.circles, 0).x |> trunc()
    my_y2 = Enum.at(socket.assigns.canvas.circles, 0).y |> trunc()
    # Get row and column ranges in a format required by Evision.Mat.roi()
    row_range = {my_y1, my_y2}
    column_range = {my_x1, my_x2}

    # Read image from file
    images = socket.assigns.images
    {image_url, _} = List.pop_at(images, socket.assigns.current)
    # IO.inspect(image_url, label: "Image_URL:")

    # Read current image
    current_image = Evision.imread("priv/static" <> image_url)
    # IO.inspect(current_image)

    # select a roi, we can do it in several ways
    # remember that ranges in Elixir are inclusive
    # dog_roi = current_image[[50..130, 80..150]]
    # dog_roi = Evision.Mat.roi(current_image, {my_x1, my_y1, 60, 60})
    image_roi = Evision.Mat.roi(current_image, row_range, column_range)
    # IO.inspect(dog_roi)

    # TODO:
    # I need to create an url, subimage_url, to add it to subimage_params and then store it in DB
    # Something like this:
    # IO.inspect(socket, label: "SOCKET:")

    subimage_url =
      "/datasets/#{socket.assigns.images_dataset_name}/#{subimage_params["label"]}/#{socket.assigns.image_time_stamp}-#{subimage_params["label"]}.jpeg"

    IO.inspect(subimage_url, label: "SUBIMAGE_URL")
    altered_params = Map.put(subimage_params, "subimage_location", subimage_url)
    IO.inspect(altered_params, label: "ALTERED PARAMS:")

    dest =
      Path.join([
        "priv",
        "static",
        "datasets",
        "#{socket.assigns.images_dataset_name}",
        "#{subimage_params["label"]}",
        "#{socket.assigns.image_time_stamp}"
      ])

    # Make directory to store images
    File.mkdir_p!(Path.dirname(dest))

    # Write roi to file
    # Note: I don't know why the liveview is restarting/reseting when Evision.imwrite() executes
    # Evision.imwrite("priv/static/images/small_dog.jpeg", image_roi)
    Evision.imwrite("priv/static" <> subimage_url, image_roi)

    {:noreply, socket}
  end

  def handle_event("canvas-click", %{"x" => x, "y" => y}, socket) do
    canvas = socket.assigns.canvas
    key = socket.id
    # payload = %{x: x, y: y}

    circle = CircleDrawer.new_circle(x, y)
    updated_canvas = CircleDrawer.add_circle(canvas, circle)

    payload = %{canvas: updated_canvas}
    updatePresence(key, payload)

    socket =
      socket
      |> assign(:canvas, updated_canvas)

    {:noreply, socket}
  end

  def handle_event("cursor-move", %{"x" => x, "y" => y}, socket) do
    key = socket.id
    payload = %{x: x, y: y}
    updatePresence(key, payload)
    {:noreply, socket}
  end

  def handle_event("send_message", %{"message" => message}, socket) do
    # IO.inspect(socket.assigns)

    # # Read image from file
    # current_image = Evision.imread("priv/static/images/dog.jpeg")
    # # Inspect current_image
    # IO.inspect(current_image)

    # # select a roi
    # dog_roi = current_image[[50..130, 80..150]]
    # # Inspect roi
    # IO.inspect(dog_roi)

    # # Write roi to file
    # Evision.imwrite("priv/static/images/small_dog.jpeg", dog_roi)

    updatePresence(socket.id, %{message: message})
    {:noreply, socket}
  end

  def handle_event("set-current", %{"key" => "Enter", "value" => value}, socket) do
    {:noreply, assign(socket, :current, String.to_integer(value))}
  end

  def handle_event("update", %{"key" => "k"}, socket) do
    {:noreply, toggle_playing(socket)}
  end

  def handle_event("update", %{"key" => "ArrowRight"}, socket) do
    {:noreply, assign(socket, :current, next(socket))}
  end

  def handle_event("update", %{"key" => "ArrowLeft"}, socket) do
    {:noreply, assign(socket, :current, previous(socket))}
  end

  def handle_event("update", _, socket) do
    {:noreply, socket}
  end

  def handle_event("toggle-playing", _, socket) do
    {:noreply, toggle_playing(socket)}
  end

  def handle_info(:tick, socket) do
    {:noreply, assign(socket, :current, next(socket))}
  end

  def handle_info(%{event: "presence_diff", payload: _payload}, socket) do
    presences =
      Presence.list(@topic)
      |> Enum.map(fn {_, data} -> data[:metas] |> List.first() end)

    socket =
      socket
      |> assign(presences: presences)
      |> assign(socket_id: socket.id)

    {:noreply, socket}
  end

  def toggle_playing(socket) do
    socket = update(socket, :is_playing, fn playing -> !playing end)

    if socket.assigns.is_playing do
      {:ok, timer} = :timer.send_interval(2000, self(), :tick)
      assign(socket, :timer, timer)
    else
      {:ok, _} = :timer.cancel(socket.assigns.timer)
      assign(socket, :timer, nil)
    end
  end

  def next(socket) do
    %{current: current, images: images} = socket.assigns

    rem(current + 1, Enum.count(images))
  end

  def previous(socket) do
    %{current: current, images: images} = socket.assigns

    rem(current - 1 + Enum.count(images), Enum.count(images))
  end

  def updatePresence(key, payload) do
    metas =
      Presence.get_by_key(@topic, key)[:metas]
      |> List.first()
      |> Map.merge(payload)

    Presence.update(self(), @topic, key, metas)
  end
end
