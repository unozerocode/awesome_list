defmodule AwesomeList do
  require Mint.HTTP
  require Jason

  @moduledoc """
  Documentation for AwesomeList.
  """

  @doc """
  Hello world.

  ## Examples

      iex> AwesomeList.hello()
      :world

  """
  def hello do
    :world
  end

  def get() do
    {:ok, conn} = Mint.HTTP.connect(_scheme = :https, _hostname = "api.github.com", _port = 443 )

    # Make a GET request to the zen path without any special headers
    {:ok, conn, request_ref} = Mint.HTTP.request(conn, _method = "GET", _path = "/zen", _headers = [], nil)

    receive do
      message ->
      # Send received message to Mint to be parsed
      {:ok, conn, responses} = Mint.HTTP.stream(conn, message)

      for response <- responses do
        case response do
          {:status, ^request_ref, status_code} ->
            IO.puts "Response status code #{status_code}"

          {:headers, ^request_ref, headers} ->
            IO.puts "Response headers:  #{inspect(headers)}"

          {:data, ^request_ref, data} ->
            IO.puts "Response Body"
            IO.puts data

          {:done, ^request_ref} ->
            IO.puts "Response fully received"
      end # case
    end # for
    end # receive
  end # get

  def readme(repo_full_name) do
    {:ok, conn} = Mint.HTTP.connect(_scheme = :https, hostname = "api.github.com", _port = 443)
    request_path = "/repos/#{repo_full_name}/readme"
    IO.puts "Request path: #{hostname}#{request_path}"
    {:ok, conn, request_ref} = Mint.HTTP.request(_conn = conn, _method = "GET", _path = request_path, _headers = [
      {"content-type", "application-json"}
    ], _body = nil)

    {:ok, conn, body} = recv_response(conn, request_ref)

    json = Jason.decode!(body)

    readme = Base.decode64!(json["content"], ignore: :whitespace)

    Mint.HTTP.close(conn)
    readme
  end # readme

  defp recv_response(conn, request_ref, body \\ []) do
    {conn, body, status} = receive do
      message ->
        {:ok, conn, mint_responses} = Mint.HTTP.stream(conn, message)

      # Reduce all messages containing a partial body
      {body, status} = Enum.reduce(mint_responses, {body, :incomplete}, fn mint_response, {body, status} ->
        case mint_response do
          # ignore status
          {:status, ^request_ref, _status_code} ->
            {body, :incomplete}

          # ignore headers
          {:headers, ^request_ref, _status_code} ->
            {body, :incomplete}

          # data brings partial body
          {:data, ^request_ref, data} ->
            {[data | body], :incomplete}

          # done brings end of response
          {:done, ^request_ref} ->
            {Enum.reverse(body), :complete}
        end #case
      end)
      {conn, body, status}
    end # receive
    if status == :complete do
      {:ok, conn, body}
    else
      recv_response(conn, request_ref, body)
    end
  end #recv_response

end # module
