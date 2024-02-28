defmodule LabelRealTimeWeb.SubimagesLive do
  use LabelRealTimeWeb, :live_view

  alias LabelRealTime.Subimages

  def mount(_params, _session, socket) do
    subimages = Subimages.list_subimages()

    {:ok, assign(socket, subimages: subimages)}
  end

  def render(assigns) do
    ~H"""
    <h1>List of Labelled Images</h1>
    <.link navigate={~p"/labelling"}>
      <div class="link-button"><.icon name="hero-arrow-left-circle" /> Back to Label</div>
    </.link>
    <.link navigate={~p"/images"}>
      <div class="link-button"><.icon name="hero-arrow-left-circle" /> Back to Upload</div>
    </.link>
    <div>
      <div :for={subimage <- @subimages}>
        <div>
          <%= subimage.label %>
        </div>
        <div>
          <img src={subimage.subimage_location} />
        </div>
      </div>
    </div>
    """
  end
end
