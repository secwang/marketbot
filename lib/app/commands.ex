defmodule App.Commands do
  use App.Router
  use App.Commander

  alias App.Commands.Outside

  def catch_null(s)  do
    if s == nil do
      "0"
    else
      s
    end
  end


  # You can create commands in the format `/command` by
  # using the macro `command "command"`.
  command "start" do
    Logger.log :info, "Command /start received"
    send_message "Hello, " <> update.message.from.username
  end

  command ["c", "coin"] do
    text = update.message.text
    [cmd, query] = String.split(text, " ")
    Logger.log :info, "cmd = #{cmd}, query = #{query} "

    ticker = Map.get(Constants.concapmarket_shortcuts, query, query)

    Logger.log :info, "queryrewrite = #{ticker} "

    url = "https://api.coinmarketcap.com/v1/ticker/#{ticker}/?convert=CNY"

    Logger.log :info, "url = #{url} "


    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        IO.puts body
        ss = Poison.decode!(body)
        [head | _] = ss
        IO.inspect head

        name = Map.get(head, "name")
        rank = Map.get(head, "rank")

        price = Map.get(head, "price_cny")
                |> catch_null
                |> Float.parse
                |> elem(0)
                |> Float.round(2)

        change_one = Map.get(head, "percent_change_1h")
                     |> catch_null
                     |> Float.parse
                     |> elem(0)
                     |> Float.round(2)
        change_two = Map.get(head, "percent_change_24h")
                     |> catch_null
                     |> Float.parse
                     |> elem(0)
                     |> Float.round(2)
        change_three = Map.get(head, "percent_change_7d")
                       |> catch_null
                       |> Float.parse
                       |> elem(0)
                       |> Float.round(2)
        volume_24h = Map.get(head, "24h_volume_cny")
                     |> catch_null
                     |> Float.parse
                     |> elem(0)
                     |> Float.round(2)


        result = """
        ```
        #{name}: ¥#{price}
        1H_CHANGE: #{change_one}%
        1D_CHANGE: #{change_two}%
        7D_CHANGE: #{change_three}%
        RANK: #{rank}
        VOLUME_24H: ¥#{volume_24h}
        ```
        """

        send_message result, [{:parse_mode, "Markdown"}]
      {:ok, %HTTPoison.Response{status_code: 404}} ->
        send_message "Not found :("
      {:error, %HTTPoison.Error{reason: reason}} ->
        send_message "REASON"
    end
  end

  command ["r", "report"] do
    Logger.log :info, "\r "


    coin_rank_url = "https://coinmarketcap.com/all/views/all/"
    volumn_rank_url = "https://coinmarketcap.com/currencies/volume/24-hour/#"
    coin_space = 300



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
                          |> Enum.take(coin_space)
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
          diff_int = coin_rank_int - coin_volume_int
      end
      Map.put(diff_map, coin, diff_int)
    end


    answer = Map.to_list(x)
             |> Enum.sort_by(&(elem(&1, 1)))
             |> Enum.reverse
             |> Enum.take(20)

    answer_message = Enum.reduce answer, "", fn {coin, diff}, acc ->
      volume = Map.get(volume_rank_map, coin)
      rank = Map.get(coin_rank_map, coin)
      acc <> "> COIN: #{coin}  \n> VOLUME_RANK: #{volume}  \n> RANK:#{rank} \n> DIFF: #{diff}\n"
    end
    send_message answer_message, [{:parse_mode, "Markdown"}]
  end

  message do
    Logger.log :warn, "Did not match the message"

    send_message "Sorry, I couldn't understand you"
  end
end
