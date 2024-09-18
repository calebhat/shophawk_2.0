defmodule Shophawk.Shopinfo.Slideshow do
  use Ecto.Schema
  import Ecto.Changeset

  schema "slideshow" do
    field :quote, :string, default: ""
    field :workhours, :string
    field :announcement1, :string, default: ""
    field :announcement2, :string, default: ""
    field :announcement3, :string, default: ""
    field :photo, :string, default: ""

    field :mondayo1, :string, virtual: true
    field :mondayc1, :string, virtual: true
    field :tuesdayo1, :string, virtual: true
    field :tuesdayc1, :string, virtual: true
    field :wednesdayo1, :string, virtual: true
    field :wednesdayc1, :string, virtual: true
    field :thursdayo1, :string, virtual: true
    field :thursdayc1, :string, virtual: true
    field :fridayo1, :string, virtual: true
    field :fridayc1, :string, virtual: true
    field :saturdayo1, :string, virtual: true
    field :saturdayc1, :string, virtual: true
    field :mondayo2, :string, virtual: true
    field :mondayc2, :string, virtual: true
    field :tuesdayo2, :string, virtual: true
    field :tuesdayc2, :string, virtual: true
    field :wednesdayo2, :string, virtual: true
    field :wednesdayc2, :string, virtual: true
    field :thursdayo2, :string, virtual: true
    field :thursdayc2, :string, virtual: true
    field :fridayo2, :string, virtual: true
    field :fridayc2, :string, virtual: true
    field :saturdayo2, :string, virtual: true
    field :saturdayc2, :string, virtual: true
    field :showsaturday1, :boolean, virtual: true, default: false
    field :showsaturday2, :boolean, virtual: true, default: false

    field :monday1closed, :boolean, virtual: true, default: false
    field :tuesday1closed, :boolean, virtual: true, default: false
    field :wednesday1closed, :boolean, virtual: true, default: false
    field :thursday1closed, :boolean, virtual: true, default: false
    field :friday1closed, :boolean, virtual: true, default: false
    field :monday2closed, :boolean, virtual: true, default: false
    field :tuesday2closed, :boolean, virtual: true, default: false
    field :wednesday2closed, :boolean, virtual: true, default: false
    field :thursday2closed, :boolean, virtual: true, default: false
    field :friday2closed, :boolean, virtual: true, default: false


    timestamps()
  end

  @doc false
  def changeset(slideshow, attrs) do
    slideshow
    |> cast(attrs, [:workhours, :announcement1, :announcement2, :announcement3, :quote, :photo])
    |> validate_required([:workhours])
  end
end
