defmodule AwesomeListTest do
  use ExUnit.Case
  doctest AwesomeList

  test "greets the world" do
    assert AwesomeList.hello() == :world
  end
end
