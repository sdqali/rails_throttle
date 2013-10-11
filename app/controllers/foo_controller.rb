class FooController < ApplicationController
  def index
    render json: {foo: :bar}
  end
end
