defmodule Philomena.Adverts do
  @moduledoc """
  The Adverts context.
  """

  import Ecto.Query, warn: false
  alias Ecto.Multi
  alias Philomena.Repo

  alias Philomena.Adverts.Advert
  alias Philomena.Adverts.Uploader

  def random_live do
    now = DateTime.utc_now()

    Advert
    |> where(live: true, restrictions: "none")
    |> where([a], a.start_date < ^now and a.finish_date > ^now)
    |> order_by(asc: fragment("random()"))
    |> limit(1)
    |> Repo.one()
  end

  def random_live_for(image) do
    image = Repo.preload(image, :tags)
    now = DateTime.utc_now()

    Advert
    |> where(live: true)
    |> where([a], a.restrictions in ^restrictions(image))
    |> where([a], a.start_date < ^now and a.finish_date > ^now)
    |> order_by(asc: fragment("random()"))
    |> limit(1)
    |> Repo.one()
  end

  defp sfw?(image) do
    image_tags = MapSet.new(image.tags |> Enum.map(& &1.name))
    sfw_tags = MapSet.new(["safe", "suggestive"])
    intersect = MapSet.intersection(image_tags, sfw_tags)

    MapSet.size(intersect) > 0
  end

  defp nsfw?(image) do
    image_tags = MapSet.new(image.tags |> Enum.map(& &1.name))
    nsfw_tags = MapSet.new(["questionable", "explicit"])
    intersect = MapSet.intersection(image_tags, nsfw_tags)

    MapSet.size(intersect) > 0
  end

  defp restrictions(image) do
    restrictions = ["none"]
    restrictions = if nsfw?(image), do: ["nsfw" | restrictions], else: restrictions
    restrictions = if sfw?(image), do: ["sfw" | restrictions], else: restrictions
    restrictions
  end

  @doc """
  Gets a single advert.

  Raises `Ecto.NoResultsError` if the Advert does not exist.

  ## Examples

      iex> get_advert!(123)
      %Advert{}

      iex> get_advert!(456)
      ** (Ecto.NoResultsError)

  """
  def get_advert!(id), do: Repo.get!(Advert, id)

  @doc """
  Creates a advert.

  ## Examples

      iex> create_advert(%{field: value})
      {:ok, %Advert{}}

      iex> create_advert(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_advert(attrs \\ %{}) do
    advert =
      %Advert{}
      |> Advert.save_changeset(attrs)
      |> Uploader.analyze_upload(attrs)

    Multi.new()
    |> Multi.insert(:advert, advert)
    |> Multi.run(:after, fn _repo, %{advert: advert} ->
      Uploader.persist_upload(advert)
      Uploader.unpersist_old_upload(advert)

      {:ok, nil}
    end)
    |> Repo.isolated_transaction(:serializable)
  end

  @doc """
  Updates a advert.

  ## Examples

      iex> update_advert(advert, %{field: new_value})
      {:ok, %Advert{}}

      iex> update_advert(advert, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_advert(%Advert{} = advert, attrs) do
    advert
    |> Advert.save_changeset(attrs)
    |> Repo.update()
  end

  def update_advert_image(%Advert{} = advert, attrs) do
    advert =
      advert
      |> Advert.changeset(attrs)
      |> Uploader.analyze_upload(attrs)

    Multi.new()
    |> Multi.update(:advert, advert)
    |> Multi.run(:after, fn _repo, %{advert: advert} ->
      Uploader.persist_upload(advert)
      Uploader.unpersist_old_upload(advert)

      {:ok, nil}
    end)
    |> Repo.isolated_transaction(:serializable)
  end

  @doc """
  Deletes a Advert.

  ## Examples

      iex> delete_advert(advert)
      {:ok, %Advert{}}

      iex> delete_advert(advert)
      {:error, %Ecto.Changeset{}}

  """
  def delete_advert(%Advert{} = advert) do
    Repo.delete(advert)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking advert changes.

  ## Examples

      iex> change_advert(advert)
      %Ecto.Changeset{source: %Advert{}}

  """
  def change_advert(%Advert{} = advert) do
    Advert.changeset(advert, %{})
  end
end
