defmodule Oasis.IntegrationTest do
  use ExUnit.Case, async: false

  setup_all do
    {:ok, _} = Oasis.HTTPServer.start(4002)

    {:ok, url: "http://localhost:4002"}
  end

  test "hello", %{url: url} do
    start_supervised!({Finch, name: TestFinch})

    url = "#{url}/hello"
    assert {:ok, response} = Finch.build(:get, url) |> Finch.request(TestFinch)
    assert response.body == "world"
  end

  test "post non validate", %{url: url} do
    start_supervised!({Finch, name: TestFinch})

    headers = [{"content-type", "application/x-www-form-urlencoded"}]
    body = "v1=k1&v2=k2"
    assert {:ok, response} = Finch.build(:post, "#{url}/test_post_non_validate", headers, body) |> Finch.request(TestFinch)

    body = Jason.decode!(response.body)
    assert %{"v1" => "k1", "v2" => "k2"} == body["body_params"]
  end

  test "exports the init/1 function" do
    assert Oasis.Gen.Plug.TestHeader.init(:ok) == :ok
    assert Oasis.Gen.Plug.TestQuery.init(:ok) == :ok
    assert Oasis.Gen.Plug.TestCookie.init(:ok) == :ok
    assert Oasis.Gen.Plug.TestPost.init(:ok) == :ok
    assert Oasis.Gen.Plug.TestDelete.init(:ok) == :ok

    assert Oasis.Plug.RequestValidator.init(:ok) == :ok
  end

  test "parse path parameter in router do body", %{url: url} do
    start_supervised!({Finch, name: TestFinch})

    id = 1
    assert {:ok, response} = Finch.build(:get, "#{url}/id/#{id}") |> Finch.request(TestFinch)
    body = Jason.decode!(response.body)
    assert body["local_var_id"] == id

    # when `id` parameter naming duplicated, follow `Plug`'s params mergence logic,
    # will reserve the path parameter `id` in the `conn.params`, not the query parameter `id`.
    id = 2

    assert {:ok, response} =
             Finch.build(:get, "#{url}/id/#{id}?id=123&a=1") |> Finch.request(TestFinch)

    body = Jason.decode!(response.body)
    assert body["local_var_id"] == id and body["conn_params"]["id"] == id

    id = "non-integer"
    assert {:ok, response} = Finch.build(:get, "#{url}/id/#{id}") |> Finch.request(TestFinch)

    assert response.status == 400 and
             response.body ==
               "Fail to transfer the value \"non-integer\" of the path parameter \"id\" by schema: %{\"type\" => \"integer\"}"
  end

  test "parse query parameter", %{url: url} do
    start_supervised!({Finch, name: TestFinch})

    id = 1
    lang = 10
    query_string = URI.encode_query(lang: lang)

    assert {:ok, response} =
             Finch.build(:get, "#{url}/test_query/#{id}?" <> query_string)
             |> Finch.request(TestFinch)

    body = Jason.decode!(response.body)
    conn_params = body["conn_params"]
    query_params = body["query_params"]

    assert conn_params["id"] == id and conn_params["lang"] == lang and
             query_params["lang"] == lang

    # duplicated `id` parameter in path and query parameter.
    id = 2
    lang = 10
    query_id = "testid"
    query_string = URI.encode_query(lang: lang, id: query_id)

    assert {:ok, response} =
             Finch.build(:get, "#{url}/test_query/#{id}?" <> query_string)
             |> Finch.request(TestFinch)

    body = Jason.decode!(response.body)
    conn_params = body["conn_params"]
    query_params = body["query_params"]

    assert conn_params["id"] == id and conn_params["lang"] == lang and
             query_params["id"] == query_id and query_params["lang"] == lang

    id = "invalid_id"
    query_string = URI.encode_query(lang: 1)

    assert {:ok, response} =
             Finch.build(:get, "#{url}/test_query/#{id}?" <> query_string)
             |> Finch.request(TestFinch)

    assert response.status == 400 and
             response.body ==
               "Fail to transfer the value \"invalid_id\" of the path parameter \"id\" by schema: %{\"type\" => \"integer\"}"

  end

  test "missing required query parameter", %{url: url} do
    start_supervised!({Finch, name: TestFinch})

    id = 1

    assert {:ok, response} =
             Finch.build(:get, "#{url}/test_query/#{id}") |> Finch.request(TestFinch)

    assert response.status == 400 and
             response.body ==
               "Required the query parameter \"lang\" is missing"
  end

  test "parse integer query param in [10, 20]", %{url: url} do
    start_supervised!({Finch, name: TestFinch})

    id = 1
    lang = 9
    query_string = URI.encode_query(lang: lang)

    assert {:ok, response} =
             Finch.build(:get, "#{url}/test_query/#{id}?" <> query_string)
             |> Finch.request(TestFinch)

    assert response.body ==
             "Expected the value to be >= 10 for the query parameter \"lang\", but got #{lang}"

    lang = 21
    query_string = URI.encode_query(lang: lang)

    assert {:ok, response} =
             Finch.build(:get, "#{url}/test_query/#{id}?" <> query_string)
             |> Finch.request(TestFinch)

    assert response.body ==
             "Expected the value to be <= 20 for the query parameter \"lang\", but got #{lang}"
  end

  test "parse boolean query parameter", %{url: url} do
    start_supervised!({Finch, name: TestFinch})

    id = 1
    lang = 10
    all = true
    query_string = URI.encode_query(lang: lang, all: all)

    assert {:ok, response} =
             Finch.build(:get, "#{url}/test_query/#{id}?" <> query_string)
             |> Finch.request(TestFinch)

    body = Jason.decode!(response.body)
    conn_params_from_resp = body["conn_params"]
    query_params_from_resp = body["query_params"]

    assert conn_params_from_resp["all"] == all and query_params_from_resp["all"] == all

    # non-required query parameter will not be existed
    assert "profile" not in Map.keys(query_params_from_resp)

    all = 0
    query_string = URI.encode_query(lang: lang, all: all)

    assert {:ok, response} =
             Finch.build(:get, "#{url}/test_query/#{id}?" <> query_string)
             |> Finch.request(TestFinch)

    assert response.body ==
             "Type mismatch. Expected Boolean but got String. for the query parameter \"all\", but got \"0\""
  end

  test "parse json in query parameter", %{url: url} do
    start_supervised!({Finch, name: TestFinch})

    id = 1
    lang = 20
    profile_tag = 1
    profile_name = "testname"
    profile = %{"tag" => profile_tag, "name" => profile_name}

    query_string = URI.encode_query(lang: lang, profile: Jason.encode!(profile))

    assert {:ok, response} =
             Finch.build(:get, "#{url}/test_query/#{id}?" <> query_string)
             |> Finch.request(TestFinch)

    body = Jason.decode!(response.body)
    conn_params = body["conn_params"]
    query_params = body["query_params"]

    query_params_profile = query_params["profile"]
    assert query_params_profile == conn_params["profile"] and query_params_profile == profile
    assert query_params["lang"] == lang

    assert query_params_profile["tag"] == profile_tag and
             query_params_profile["name"] == profile_name

    profile_tag = "invalid"
    profile = %{profile | "tag" => profile_tag}
    query_string = URI.encode_query(lang: lang, profile: Jason.encode!(profile))

    assert {:ok, response} =
             Finch.build(:get, "#{url}/test_query/#{id}?" <> query_string)
             |> Finch.request(TestFinch)

    assert response.status == 400 and
             response.body ==
               "Type mismatch. Expected Integer but got String. for the query parameter \"profile\" in \"#/tag\", but got %{\"name\" => \"testname\", \"tag\" => \"invalid\"}"
  end

  test "parse array header parameter", %{url: url} do
    start_supervised!({Finch, name: TestFinch})

    items = [1, 2, 3]
    headers = [{"items", Jason.encode!(items)}]

    assert {:ok, response} =
             Finch.build(:get, "#{url}/test_header", headers) |> Finch.request(TestFinch)

    body = Jason.decode!(response.body)
    assert body["items"] == items

    # all headers naming will be downcased
    headers = [{"iTeMs", Jason.encode!(items)}]

    assert {:ok, response} =
             Finch.build(:get, "#{url}/test_header", headers) |> Finch.request(TestFinch)

    body = Jason.decode!(response.body)
    assert body["items"] == items

    items = ["a", "b", "c"]
    headers = [{"items", Jason.encode!(items)}]

    assert {:ok, response} =
             Finch.build(:get, "#{url}/test_header", headers) |> Finch.request(TestFinch)

    assert response.status == 400 and
             response.body ==
               "Type mismatch. Expected Integer but got String. for the header parameter \"items\" in \"#/0\", but got [\"a\", \"b\", \"c\"]"
  end

  test "missing required header parameter", %{url: url} do
    start_supervised!({Finch, name: TestFinch})

    assert {:ok, response} = Finch.build(:get, "#{url}/test_header") |> Finch.request(TestFinch)

    assert response.status == 400 and
             response.body ==
               "Required the header parameter \"items\" is missing"

    headers = [{"name", "testname"}]

    assert {:ok, response} =
             Finch.build(:get, "#{url}/test_header", headers) |> Finch.request(TestFinch)

    assert response.status == 400 and
             response.body ==
               "Required the header parameter \"items\" is missing"
  end

  test "missing required cookie parameter", %{url: url} do
    start_supervised!({Finch, name: TestFinch})

    headers = [{"Cookie", "a=1; b=2"}]

    assert {:ok, response} =
             Finch.build(:get, "#{url}/test_cookie", headers) |> Finch.request(TestFinch)

    assert response.status == 400 and
             response.body ==
               "Required the cookie parameter \"items\" is missing"
  end

  test "parse array cookie parameter", %{url: url} do
    start_supervised!({Finch, name: TestFinch})

    headers = [{"Cookie", "items=[1,2,3]"}]

    assert {:ok, response} =
             Finch.build(:get, "#{url}/test_cookie", headers) |> Finch.request(TestFinch)

    body = Jason.decode!(response.body)
    assert body == %{"req_cookies" => %{"items" => [1, 2, 3]}}

    resp_cookies =
      Enum.reduce(response.headers, [], fn
        {"set-cookie", value}, acc ->
          [value | _] = String.split(value, ";")
          [{"cookie", value} | acc]

        _, acc ->
          acc
      end)

    headers = [{"cookie", "items=[4, 5.6, 6]"} | resp_cookies]

    assert {:ok, response} =
             Finch.build(:get, "#{url}/test_cookie", headers) |> Finch.request(TestFinch)

    body = Jason.decode!(response.body)

    # DO NOT process signed / encrypted cookie, reserved for specific business processing
    %{"items" => items, "testcookie1" => signed_cookie1, "testcookie2" => signed_cookie2} =
      body["req_cookies"]

    assert items == [4, 5.6, 6]
    assert is_bitstring(signed_cookie1) and is_bitstring(signed_cookie2)
  end

  test "post urlencoded", %{url: url} do
    start_supervised!({Finch, name: TestFinch})

    headers = [{"content-type", "application/x-www-form-urlencoded"}]
    body = "name=v1&fav_number=1"
    assert {:ok, response} =
             Finch.build(:post, "#{url}/test_post_urlencoded?q1=123", headers, body) |> Finch.request(TestFinch)

    body = Jason.decode!(response.body)

    %{"fav_number" => fav_number, "name" => name} = body["body_params"]
    assert fav_number == 1 and name == "v1"

    %{"fav_number" => fav_number, "name" => name, "q1" => q1} = body["params"]
    assert fav_number == 1 and name == "v1" and q1 == "123"

    # a query parameter with the same naming in request body
    # in this case, will keep parameters of request body in the `conn.params`,
    # follow the process priority of `Plug`.
    body = "name=v1&fav_number=1"
    assert {:ok, response} =
             Finch.build(:post, "#{url}/test_post_urlencoded?name=fromquery&fav_number=abc", headers, body) |> Finch.request(TestFinch)

    body = Jason.decode!(response.body)
    body_params = body["body_params"]
    params = body["params"]

    %{"fav_number" => fav_number, "name" => name} = body_params
    assert fav_number == 1 and name == "v1"
    assert body_params == params

    body = "name=v1&fav_number=abc"
    assert {:ok, response} =
             Finch.build(:post, "#{url}/test_post_urlencoded", headers, body) |> Finch.request(TestFinch)

    assert response.status == 400 and
             response.body ==
               "Fail to transfer the value %{\"fav_number\" => \"abc\", \"name\" => \"v1\"} of the body request by schema: %{\"properties\" => %{\"fav_number\" => %{\"maximum\" => 3, \"minimum\" => 1, \"type\" => \"integer\"}, \"name\" => %{\"type\" => \"string\"}}, \"required\" => [\"name\", \"fav_number\"], \"type\" => \"object\"}"

    body = "name=v1&fav_number=0"
    assert {:ok, response} =
             Finch.build(:post, "#{url}/test_post_urlencoded", headers, body) |> Finch.request(TestFinch)

    assert response.status == 400 and
             response.body ==
               "Expected the value to be >= 1 for the body request in \"#/fav_number\", but got %{\"fav_number\" => 0, \"name\" => \"v1\"}"
  end

  test "post multipart/formdata", %{url: url} do
    start_supervised!({Finch, name: TestFinch})

    headers = [{"content-type", "multipart/form-data; boundary=--76b20336b057"}]

    multipart = """
    ----76b20336b057\r
    Content-Disposition: form-data; name=\"id\"\r
    \r
    1\r
    ----76b20336b057\r
    Content-Disposition: form-data; name=\"username\"\r
    \r
    hello\r
    ----76b20336b057--\r
    """

    assert {:ok, response} =
             Finch.build(:post, "#{url}/test_post_multipart", headers, multipart) |> Finch.request(TestFinch)

    body = Jason.decode!(response.body)
    body_params = body["body_params"]
    assert %{"id" => 1, "username" => "hello"} = body_params

    # a valid `id` parameter should be <= 10, but input 20
    multipart = """
    ----76b20336b057\r
    Content-Disposition: form-data; name=\"id\"\r
    \r
    20\r
    ----76b20336b057\r
    Content-Disposition: form-data; name=\"username\"\r
    \r
    hello\r
    ----76b20336b057--\r
    """

    assert {:ok, response} =
             Finch.build(:post, "#{url}/test_post_multipart", headers, multipart) |> Finch.request(TestFinch)

    assert response.status == 400 and
      response.body ==
        "Expected the value to be <= 10 for the body request in \"#/id\", but got %{\"id\" => 20, \"username\" => \"hello\"}"
  end

  test "post multipart/mixed", %{url: url} do
    start_supervised!({Finch, name: TestFinch})

    headers = [{"content-type", "multipart/mixed; boundary=--76b20336b057"}]

    multipart = """
    ----76b20336b057\r
    Content-Disposition: form-data; name=\"id\"\r
    \r
    testid\r
    ----76b20336b057\r
    Content-Disposition: form-data; name=\"addresses\"\r
    Content-Type: application/json\r
    \r
    [{"number":1, "name": "testname1"}, {"number":2, "name": "testname2"}]\r
    ----76b20336b057--\r
    """

    assert {:ok, response} =
             Finch.build(:post, "#{url}/test_post_multipart", headers, multipart) |> Finch.request(TestFinch)

    body = Jason.decode!(response.body)
    body_params = body["body_params"]

    assert %{"id" => "testid", "addresses" => [%{"number" => 1, "name" => "testname1"}, %{"number" => 2, "name" => "testname2"}]} == body_params
    assert body_params == body["params"]

    # missing required `addresses`
    multipart = """
    ----76b20336b057\r
    Content-Disposition: form-data; name=\"id\"\r
    \r
    testid\r
    ----76b20336b057\r
    Content-Type: application/json\r
    \r
    [{"number":1, "name": "testname1"}, {"number":2, "name": "testname2"}]\r
    ----76b20336b057--\r
    """

    assert {:ok, response} =
             Finch.build(:post, "#{url}/test_post_multipart", headers, multipart) |> Finch.request(TestFinch)

    assert response.status == 400 and
      response.body ==
        "Required property addresses was not present. for the body request, but got %{\"id\" => \"testid\"}"
  end

  test "delete request with body schema validation", %{url: url} do
    start_supervised!({Finch, name: TestFinch})

    headers = [{"content-type", "application/x-www-form-urlencoded"}]
    body = "k1=1&k2=2"

    assert {:ok, response} =
             Finch.build(:delete, "#{url}/test_delete", headers, body) |> Finch.request(TestFinch)

    assert response.body == "Required the query parameter \"id\" is missing"

    query_string = URI.encode_query(id: 1, relation_ids: Jason.encode!([1, 2, 3]))
    assert {:ok, response} =
             Finch.build(:delete, "#{url}/test_delete?" <> query_string, headers, body) |> Finch.request(TestFinch)

    assert response.body ==
      "Type mismatch. Expected String but got Integer. for the query parameter \"relation_ids\" in \"#/0\", but got [1, 2, 3]"

    query_string = URI.encode_query(id: 1, relation_ids: Jason.encode!(["1", "2", "3"]))
    assert {:ok, response} =
             Finch.build(:delete, "#{url}/test_delete?" <> query_string, headers, body) |> Finch.request(TestFinch)

    assert response.status == 200

    body = Jason.decode!(response.body)

    # no any body schema use to validate
    assert %{"k1" => "1", "k2" => "2"} == body["body_params"]

    assert body["conn_params"] == Map.merge(body["body_params"], body["query_params"])

    # parse query parameters
    assert %{"id" => 1, "relation_ids" => ["1", "2", "3"]} == body["query_params"]
  end

end