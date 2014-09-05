require 'pry'
require_relative 'ingredient'

class Recipe
  attr_reader :id, :name, :description, :instructions, :ingredients

  def initialize (id, name, instructions = nil, description = nil, ingredients = [])
    @id = id
    @name = name
    @instructions = instructions
    @description = description
    @ingredients = ingredients
  end

  def self.db_connection
  begin
    connection = PG.connect(dbname: 'recipes')

    yield(connection)

  ensure
    connection.close
  end
end

  def self.all
    recipes = []
    temp = db_connection do |conn|
      conn.exec("SELECT id, name, instructions, description FROM recipes")
    end
    temp.each do |t|
      recipes << Recipe.new(t["id"], t["name"], t["instructions"], t["description"])
    end
    recipes
  end

  def self.find(id)
    temp_hash = db_connection do |conn|
      conn.exec("SELECT id, name, instructions, description FROM recipes
                  WHERE id = $1", [id])
    end
    temp_hash = temp_hash.first

    temp_ingredients = db_connection do |conn|
      conn.exec("SELECT ingredients.name FROM ingredients
                WHERE ingredients.recipe_id = $1", [id])
    end

    ingredients = []
    temp_ingredients.each do |temp|
      ingredients << Ingredient.new(temp["id"], temp["name"])
    end



    if temp_hash["description"] == nil
      temp_hash["description"] = "This recipe doesn't have a description."
    end

    if temp_hash["instructions"] == nil
      temp_hash["instructions"] = "This recipe doesn't have any instructions."
    end

    Recipe.new(temp_hash["id"], temp_hash["name"], temp_hash["instructions"], temp_hash["description"], ingredients)
  end

end
