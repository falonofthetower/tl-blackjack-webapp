require 'pry'
require 'rubygems'
require 'sinatra'
require 'shotgun'

set :sessions, true

DEALER_HIT_VALUE = 17
BLACKJACK_VALUE = 21

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
 #session[:bet] = 0
 #session[:cash] = 0
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
    break if total <= BLACKJACK_VALUE
    total -= 10
  end

  total
end

def bust?(hand)
  calculate_total(hand) > BLACKJACK_VALUE
end

def blackjack?(hand)
  calculate_total(hand) == BLACKJACK_VALUE && hand.count == 2
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

def bet_made?
  session[:bet] != 0
end

before /^(?!\/(name_form))/ do
  redirect '/name_form' unless session[:name]
end

before /^(?!\/(bet_form|name_form))/ do
  redirect '/bet_form' unless session[:bet]
end   

get '/' do
  redirect '/name_form'
end

get '/name_form' do
  session.clear
  session[:cash] = 500
  erb :name_form
end

get '/bet_form' do
  erb :bet_form
end


get '/game' do  
  redirect '/' if !session[:name]  
  start_game
  session[:turn] = "player"
  @message = "#{session[:name]}, welcome to Blackjack"  
  erb :game    
end

post '/game/player/hit' do    
  session[:player_hand] << session[:deck].pop  
  if bust? session[:player_hand]    
    @error = "Sorry you have busted"    
    session[:turn] = "dealer"
    redirect '/game/comparison'
  end
  @message = "#{session[:name]}, hits" unless @error 
  erb :game
end

post '/game/player/stay' do
  session[:player_done] = true
  @show_hit_or_stay_buttons = false
  @message = "#{session[:name]} has stayed"  
  session[:turn] = "dealer"
  erb :game
end

post '/game/dealer/continue' do
  @message = "Dealer holds BLACKJACK_VALUE!" if blackjack? session[:dealer_hand]  
  if calculate_total(session[:dealer_hand]) < DEALER_HIT_VALUE
    session[:dealer_hand] << session[:deck].pop 
    @message = "Dealer takes a card"
  else
    redirect '/game/comparison'    
  end
  @message = "Dealer has busted!" if bust? session[:dealer_hand]
  redirect '/game/comparison' if calculate_total(session[:dealer_hand]) > 16    
  @message = "Now the dealer plays" unless @message

  erb :game
end

post '/name_form' do
  if params[:name] == ''
    @error = "You must enter a name"
    erb :name_form
  else
    session[:name] = params[:name]
    session[:cash]
    redirect '/bet_form'
  end    
end

post '/bet_form' do
  if params[:bet].to_i == 0
    @error = "You must bet something!"
    erb :bet_form 
  elsif params[:bet].to_i > session[:cash]
    @error = "You don't have that much to bet"
    erb :bet_form
  else
    session[:bet] = params[:bet].to_i
    session[:cash] -= session[:bet]
    redirect '/game'
  end
end

get '/game/comparison' do
  dealer_total = calculate_total(session[:dealer_hand])
  player_total = calculate_total(session[:player_hand])
  if player_total > BLACKJACK_VALUE
    @error = "#{session[:name]} busts!"
  elsif (blackjack?(session[:player_hand]) && blackjack?(session[:dealer_hand])) || player_total == dealer_total
    session[:cash] += session[:bet]
    @message = "Push"
  elsif blackjack?(session[:dealer_hand])
    @error = "Dealer Blackjack!"  
  elsif blackjack?(session[:player_hand])
    session[:cash] += session[:bet] * 2.5
    @success = "#{session[:name]} Blackjack's!"
  elsif player_total > dealer_total
    session[:cash] += session[:bet] * 2
    @success = "#{session[:name]} Wins!"
  elsif dealer_total > BLACKJACK_VALUE
    session[:cash] += session[:bet] * 2
    @success = "Dealer Busts! #{session[:name]} wins!"
  elsif dealer_total > player_total
    @error = "Dealer wins. #{session[:name]} loses!"
  end
  session[:bet] = 0
  session[:turn] = "nil"
  session[:again?] = true
  erb :game
end