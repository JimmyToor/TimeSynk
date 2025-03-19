# frozen_string_literal: true

class GameGateway
  GAMES_ONLY = "version_parent = null & (category = 0 | category = 4)"

  # Initializes a new GameGateway instance
  # Sets up the IGDB client with credentials from AppConfig
  def initialize
    @client = IGDB::Client.new(AppConfig.get("IGDB.CLIENT"), AppConfig.get("IGDB.SECRET"))
  end

  # Finds a game by its IGDB ID
  # @param id [Integer] The IGDB ID of the game to find
  # @param fields [Hash] The fields to retrieve, defaults to all fields
  # @return [Hash] The game data
  def find_by_id(id, fields = {fields: "*"})
    @client.id(id, fields)
  end

  # Searches for games matching the given query
  # @param query [String] The search query
  # @param fields [Hash] The fields to retrieve, defaults to all fields
  # @return [Array<Hash>] Array of game data matching the search
  def search(query, fields = {fields: "*"})
    @client.search(query, fields)
  end

  # Fetches games from the IGDB API
  # @param fields [String] The fields to retrieve, defaults to all fields
  # @param limit [Integer] The maximum number of games to retrieve, defaults to 10
  # @param sort [String] The sorting criteria, defaults to "first_release_date desc"
  # @param where [String, nil] Additional filter conditions, defaults to nil
  # @return [Array<Hash>] Array of game data
  def fetch_games(fields: "*", limit: 10, sort: "first_release_date desc", where: nil)
    params = {fields: fields, limit: limit, sort: sort}
    params[:where] = where unless where.nil?
    @client.endpoint = "games"
    @client.get(params)
  end

  # Fetches popular game IDs from the IGDB API
  # @param fields [String] The fields to retrieve, defaults to "game_id,value,popularity_type"
  # @param limit [Integer] The maximum number of games to retrieve, defaults to 10
  # @param sort [String] The sorting criteria, defaults to "value desc"
  # @param popularity_type [Integer] The type of popularity to filter by, defaults to 5
  # @return [Array<Hash>] Array of popular game data
  def fetch_popular_game_ids(fields: "game_id,value,popularity_type", limit: 10, sort: "value desc", popularity_type: 5)
    params = {fields: fields, limit: limit, sort: sort, where: "popularity_type = #{popularity_type}"}
    @client.endpoint = "popularity_primitives"
    @client.get(params)
  end

  # Fetches all games from the IGDB API
  # @param fields [String] The fields to retrieve, defaults to all fields
  # @param limit [Integer] The batch size for fetching games, defaults to 500
  # @param sort [String] The sorting criteria, defaults to "id asc"
  # @param offset [Integer] The offset for pagination, defaults to 0
  # @return [Array<Hash>] Array of all games data
  def fetch_all_games(fields: "*", limit: 500, sort: "id asc", offset: 0)
    @client.endpoint = "games/count"
    count = fetch_game_count

    @client.endpoint = "games"
    games = []

    while offset < count
      puts "Starting fetch of games from offset #{offset}..."

      params = {fields: fields, limit: limit, sort: sort, offset: offset, where: GAMES_ONLY}
      games.concat @client.get(params)

      offset += limit

      puts "Fetched #{games.count} games out of #{count}"
    end
    games
  end

  # Fetches all new games created since a specified date
  # @param fields [String] The fields to retrieve, defaults to all fields
  # @param limit [Integer] The batch size for fetching games, defaults to 500
  # @param sort [String] The sorting criteria, defaults to "id asc"
  # @param offset [Integer] The offset for pagination, defaults to 0
  # @param date [DateTime] The date since which to fetch new games, defaults to latest created_at or 1 week ago if database is empty
  # @return [Array<Hash>] Array of new games data
  def fetch_all_new_games(fields: "*", limit: 500, sort: "id asc", offset: 0, date: Game.maximum(:created_at) || 1.week.ago)
    @client.endpoint = "games/count"
    where = "#{GAMES_ONLY} & created_at >= #{date.to_i}"
    count = fetch_game_count(where: where)

    @client.endpoint = "games"
    games = []

    while offset < count
      puts "Starting fetch of new games from offset #{offset}..."

      params = {fields: fields, limit: limit, sort: sort, offset: offset, where: where}
      games.concat @client.get(params)

      offset += limit

      puts "Fetched #{games.count} games out of #{count}"
    end
    games
  end

  # Fetches all games updated since a specified date
  # @param fields [String] The fields to retrieve, defaults to all fields
  # @param limit [Integer] The batch size for fetching games, defaults to 500
  # @param sort [String] The sorting criteria, defaults to "id asc"
  # @param offset [Integer] The offset for pagination, defaults to 0
  # @param date [DateTime] The date since which to fetch updated games, defaults to latest updated_at or 1 week ago
  # @return [Array<Hash>] Array of updated games data
  def fetch_all_updated_games(fields: "*", limit: 500, sort: "id asc", offset: 0, date: Game.maximum(:updated_at) || 1.week.ago)
    @client.endpoint = "games/count"
    where = "#{GAMES_ONLY} & updated_at >= #{date.to_i}"
    count = fetch_game_count(where: where)

    @client.endpoint = "games"
    games = []

    while offset < count
      puts "Starting fetch of updated games from offset #{offset}..."

      params = {fields: fields, limit: limit, sort: sort, offset: offset, where: where}
      games.concat @client.get(params)

      offset += limit

      puts "Fetched #{games.count} games out of #{count}"
    end
    games
  end

  # Fetches a batch of games starting from the specified offset
  # @param fields [String] The fields to retrieve, defaults to all fields
  # @param limit [Integer] The batch size for fetching games, defaults to 500
  # @param sort [String] The sorting criteria, defaults to "id asc"
  # @param offset [Integer] The offset for pagination, defaults to 0
  # @return [Array<Hash>] Array of games data for the retrieved batch
  def fetch_batch_of_games(fields: "*", limit: 500, sort: "id asc", offset: 0)
    @client.endpoint = "games"
    games = []

    puts "Starting fetch of games from offset #{offset}..."

    params = {fields: fields, limit: limit, sort: sort, offset: offset, where: GAMES_ONLY}
    games.concat @client.get(params)

    puts "Fetched #{games.count} games"
    games
  end

  # Gets the total count of games matching the specified conditions
  # @param where [String, nil] Additional filter conditions, defaults to nil
  # @return [Integer] The count of games
  def fetch_game_count(where: nil)
    old_endpoint = @client.endpoint
    @client.endpoint = "games/count"
    where = if where.present?
      "#{GAMES_ONLY} & #{where}"
    else
      GAMES_ONLY
    end
    params = {where: where}

    count = @client.get(params).count

    @client.endpoint = old_endpoint
    count
  end
end
