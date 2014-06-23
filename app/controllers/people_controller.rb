class PeopleController < ApplicationController
  def index
    @people = Person.all
  end

  def import
    Person.import(params[:file])
    redirect_to people_path, notice: "People imported."
  end

  def calculate_distance
    Person.calculate_distance( params[:person][:destination] )
    redirect_to people_path, notice: "Distances have been calculated"
  end

  def export
    @people = Person.all

    respond_to do |format|
      format.html { redirect_to(people_path) }
      format.csv { send_data @people.as_csv, filename: 'distance_calculations.csv' }
    end
  end

  def delete_all
    Person.destroy_all
    redirect_to people_path, notice: "Aaargh its all gone"
  end
end
