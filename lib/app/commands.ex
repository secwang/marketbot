defmodule App.Commands do
  use App.Router
  use App.Commander

  alias App.Commands.Outside


  catch_null = fn (s) ->
    if s == "null" do
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

  message do
    Logger.log :warn, "Did not match the message"

    send_message "Sorry, I couldn't understand you"
  end
end
