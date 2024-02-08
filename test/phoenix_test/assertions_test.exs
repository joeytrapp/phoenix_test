defmodule PhoenixTest.AssertionsTest do
  use ExUnit.Case, async: true

  import PhoenixTest
  alias ExUnit.AssertionError

  setup do
    %{conn: Phoenix.ConnTest.build_conn()}
  end

  describe "assert_has/3" do
    test "succeeds if single element is found with CSS selector and text (Static)", %{conn: conn} do
      conn =
        conn
        |> visit("/page/index")

      conn |> assert_has("h1", "Main page")

      conn
      |> assert_has("#title", "Main page")
      |> assert_has(".title", "Main page")

      conn |> assert_has("[data-role='title']", "Main page")
    end

    test "succeeds if single element is found with CSS selector and text (Live)", %{conn: conn} do
      conn =
        conn
        |> visit("/live/index")

      conn |> assert_has("h1", "LiveView main page")

      conn
      |> assert_has("#title", "LiveView main page")
      |> assert_has(".title", "LiveView main page")

      conn |> assert_has("[data-role='title']", "LiveView main page")
    end

    test "succeeds if more than one element matches selector but text narrows it down", %{
      conn: conn
    } do
      conn
      |> visit("/page/index")
      |> assert_has("li", "Aragorn")
    end

    test "succeeds if text difference is only a matter of truncation", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> assert_has(".has_extra_space", "Has extra space")
    end

    test "raises an error if the element cannot be found at all", %{conn: conn} do
      conn = visit(conn, "/page/index")

      msg = ~r/Could not find any elements with selector "#nonexistent-id"/

      assert_raise AssertionError, msg, fn ->
        conn |> assert_has("#nonexistent-id", "Main page")
      end
    end

    test "raises error if element cannot be found but selector matches other elements", %{
      conn: conn
    } do
      conn = visit(conn, "/page/index")

      msg =
        """
        Could not find element with text "Super page".

        Found other elements matching the selector "h1":

        <h1 id="title" class="title" data-role="title">
          Main page
        </h1>
        """
        |> ignore_whitespace()

      assert_raise AssertionError, msg, fn ->
        conn |> assert_has("h1", "Super page")
      end
    end

    test "raises error if element cannot be found and selector matches a nested structure", %{
      conn: conn
    } do
      conn = visit(conn, "/page/index")

      msg =
        """
        Could not find element with text "Frodo".

        Found other elements matching the selector "#multiple-items":

        <ul id="multiple-items">
          <li>
            Aragorn
          </li>
          <li>
            Legolas
          </li>
          <li>
            Gimli
          </li>
        </ul>
        """
        |> ignore_whitespace()

      assert_raise AssertionError, msg, fn ->
        conn |> assert_has("#multiple-items", "Frodo")
      end
    end
  end

  describe "refute_has/3" do
    test "succeeds if no element is found with CSS selector and text (Static)", %{conn: conn} do
      conn =
        conn
        |> visit("/page/index")

      conn |> refute_has("h1", "Not main page")

      conn
      |> refute_has("h2", "Main page")
      |> refute_has("#incorrect-id", "Main page")

      conn |> refute_has("#title", "Not main page")
    end

    test "succeeds if no element is found with CSS selector and text (Live)", %{conn: conn} do
      conn =
        conn
        |> visit("/live/index")

      conn |> refute_has("h1", "Not main page")

      conn
      |> refute_has("h2", "Main page")
      |> refute_has("#incorrect-id", "Main page")

      conn |> refute_has("#title", "Not main page")
    end

    test "raises an error if one element is found", %{conn: conn} do
      conn = visit(conn, "/page/index")

      msg =
        """
        Expected not to find an element.

        But found an element with selector "#title" and text "Main page":

        <h1 id="title" class="title" data-role="title">
          Main page
        </h1>
        """
        |> ignore_whitespace()

      assert_raise AssertionError, msg, fn ->
        conn |> refute_has("#title", "Main page")
      end
    end

    test "raises an error if multiple elements are found", %{conn: conn} do
      conn = visit(conn, "/page/index")

      msg =
        """
        Expected not to find an element.

        But found 2 elements with selector ".multiple_links" and text "Multiple links":
        """
        |> ignore_whitespace()

      assert_raise AssertionError, msg, fn ->
        conn |> refute_has(".multiple_links", "Multiple links")
      end
    end
  end

  # converts a multi-line string into a whitespace-forgiving regex
  defp ignore_whitespace(string) do
    string
    |> String.split("\n")
    |> Enum.map(&String.trim/1)
    |> Enum.reject(fn s -> s == "" end)
    |> Enum.map(fn s -> "\\s*" <> s <> "\\s*" end)
    |> Enum.join("\n")
    |> Regex.compile!([:dotall])
  end
end
