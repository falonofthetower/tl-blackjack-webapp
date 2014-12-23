require 'pry'
require 'rubygems'
require 'sinatra'
require 'shotgun'

set :sessions, true

before do
  @show_hit_or_stay_buttons = true
end

def image_helper(card)
  image_string = ""
  case card[0]
  when "C"
    image_string << "clubs_"
  when "S"
    image_string << "spades_"
  when "D"
    image_string << "diamonds_"
  when "H"
    image_string << "hearts_"    
  end

  case card[1]
  when "A"
    image_string << "ace"
  when "K"
    image_string << "king"
  when "J"
    image_string << "jack"
  when "Q"
    image_string << "queen"
  else 
    image_string << card[1]
  end
  image_string << ".jpg"
end

def start_game

  session[:bet] = 0
  session[:cash] = 0
  session[:player_hand] = []
  session[:dealer_hand] = []  
  suits = ['H', 'D', 'S', 'C']
  face = ['2','3','4','5','6','7','8','9','10','J','Q','K','A']
  session[:deck] = suits.product(face).shuffle!  
  session[:player_hand] << session[:deck].pop
  session[:dealer_hand] << session[:deck].pop
  session[:player_hand] << session[:deck].pop
  session[:dealer_hand] << session[:deck].pop   
end

def calculate_total(hand)
  total = 0
  
  count = hand.map { |each| each[1] }

  count.each do |value|
    if value == "A"
      total += 11
    else
      total += value.to_i == 0 ? 10 : value.to_i
    end
  end

  count.select{|each| each == "A"}.count.times do
    break if total <= 21
    total -= 10
  end

  total
end

def bust?(hand)
  calculate_total(hand) > 21
end

def blackjack?(hand)
  calculate_total(hand) == 21 && hand.count == 2
end

def dealer_turn
  begin
    total = calculate_total(session[:dealer_hand])
    if total > 16
      session[:dealer_done] = true
    else
      session[:dealer_hand] << session[:deck].pop
    end   
  end until session[:dealer_done] == true
end

def calculate_winner
  session[:game_over] = true
end

get '/' do
  session.clear    
  erb :name_form
end

get '/game' do  
  redirect '/' if !session[:name]
  start_game
  erb :game    
end

post '/game/player/hit' do    
  session[:player_hand] << session[:deck].pop  
  if bust? session[:player_hand]    
    @error = "Sorry you have busted"
    @show_hit_or_stay_buttons = false
  end  
  erb :game
end

post '/game/player/stay' do
  session[:player_done] = true
  @show_hit_or_stay_buttons = false
  @message = "You have stayed"
  erb :game
end

post '/name_form' do
  if params[:name] == ''
    @error = "You must enter a name"
    erb :name_form
  else
    session[:name] = params[:name]
    redirect '/game'
  end    
end