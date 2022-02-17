class PeopleController < ApplicationController
  def show
    @person = PersonView.find(params[:id])
  end
end