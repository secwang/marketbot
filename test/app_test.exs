defmodule AppTest do
  use ExUnit.Case
  doctest App

  test "the truth" do
    assert 1 + 1 == 2
  end



  test "get the app" do


    coin_rank_url = "https://coinmarketcap.com/all/views/all/"
    volumn_rank_url = "https://coinmarketcap.com/currencies/volume/24-hour/#"



    coin_rank_map = %{}
    case HTTPoison.get(coin_rank_url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        coin_rank_string = Floki.find(body, ".currency-name-container")
                           |> Floki.text([sep: "|"])
                           |> String.downcase



        coin_rank_map = String.split(coin_rank_string, "|")
                        |> Enum.with_index
                        |> Map.new

      {:ok, %HTTPoison.Response{status_code: 404}} ->
        nil
      {:error, %HTTPoison.Error{reason: reason}} ->
        nil
    end

    volume_rank_map = %{}
    case HTTPoison.get(volumn_rank_url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        volumn_rank_string = Floki.find(body, ".volume-header > a")
                             |> Floki.text([sep: "|"])
                             |> String.downcase

        volume_rank_map = String.split(volumn_rank_string, "|")
                          |> Enum.with_index
                          |> Map.new

      #        IO.inspect volume_rank_map

      {:ok, %HTTPoison.Response{status_code: 404}} ->
        nil
      {:error, %HTTPoison.Error{reason: reason}} ->
        nil
    end


    min = -999999
    x = Enum.reduce coin_rank_map, %{}, fn {coin, coin_rank_int}, diff_map ->
      coin_volume_int = Map.get(volume_rank_map, coin)
      case {coin_volume_int, coin_rank_int} do
        {nil, y} ->
          diff_int = min
        {x, nil} ->
          diff_int = min
        {nil, nil} ->
          diff_int = min
        {x, y} ->
          diff_int = coin_volume_int - coin_rank_int
      end
      Map.put(diff_map, coin, diff_int)
    end


    answer = Map.to_list(x)
             |> Enum.sort_by(&(elem(&1, 1)))
             |> Enum.reverse


    IO.inspect(answer)

  end


end
