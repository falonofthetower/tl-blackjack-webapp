require 'pry'
require 'rubygems'
require 'sinatra'
require 'shotgun'

set :sessions, true

before do
  @show_hit_or_stay_buttons = true  
end

def image_helper(card)  
  if card == "cover"
    "<img src='/images/cards/cover.jpg' class='card_image'>"
  else

    suit = case card[0]
    when "C" then "clubs"
    when "S" then "spades"
    when "D" then "diamonds"
    when "H" then "hearts"    
    end

    value = case card[1]
    when "A" then "ace"
    when "K" then "king"
    when "J" then "jack"
    when "Q" then "queen"
    else card[1]
    end
  
    "<img src='/images/cards/#{suit}_#{value}.jpg' class='card_image'>"
  end
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
    @show_dealer_items = true    
  end  
  erb :game
end

post '/game/player/stay' do
  session[:player_done] = true
  @show_hit_or_stay_buttons = false
  @message = "#{session[:name]} has stayed"
  @show_hit_or_stay_buttons = false
  @show_dealer_items = true
  erb :game
end

post '/game/dealer/continue' do
  @message = "Dealer holds blackjack!" if blackjack? session[:dealer_hand]  
  if calculate_total(session[:dealer_hand]) < 17
    session[:dealer_hand] << session[:deck].pop 
  else
    redirect '/game/comparison'    
  end
  @message = "Dealer has busted!" if bust? session[:dealer_hand]
  redirect '/game/comparison' if calculate_total(session[:dealer_hand]) > 16
  @show_hit_or_stay_buttons = false
  @show_dealer_items = true
  @show_dealer_card = true
  erb :game
end

get 'game/dealer' do
  @show_hit_or_stay_buttons = false
  @show_dealer_items = true
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

get '/game/comparison' do
  dealer_total = calculate_total(session[:dealer_hand])
  player_total = calculate_total(session[:player_hand])
  if player_total > 21
    @error = "#{session[:name]} busts!"
  elsif (blackjack?(session[:player_hand]) && blackjack?(dealer)) || player_total == dealer_total
    #player[:chips] += player[:bet]
    @message = "Push"
  elsif blackjack?(session[:dealer_hand])
    @error = "Dealer BlackJack!"  
  elsif blackjack?(session[:player_hand])
    #player[:chips] += player[:bet] * 2.5
    @success = "#{session[:name]} BlackJack's!"
  elsif player_total > dealer_total
    #player[:chips] += player[:bet] * 2
    @success = "#{session[:name]} Wins!"
  elsif dealer_total > 21
    #player[:chips] += player[:bet] * 2
    @success = "Dealer Busts! #{session[:name]} wins!"
  elsif dealer_total > player_total
    @error = "Dealer wins. #{session[:name]} loses!"
  end
  @show_hit_or_stay_buttons = false
  @show_play_again_button = true
  @show_dealer_card = true
  erb :game
end