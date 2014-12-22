require 'pry'
require 'rubygems'
require 'sinatra'
require 'shotgun'
require 'rack-flash'
set :sessions, true
use Rack::Flash

get '/' do  
  if session[:name]
    redirect '/game'
  else
    redirect '/name_form'
  end    
end

get '/name_form' do
  erb :name_form
end

post '/name_form' do
  if params[:name] == ''
    flash[:notice] = "You must enter a name"
    redirect '/'
  else
    session[:name] = params[:name]
  end
  redirect '/game'  
end

def start_game
  session[:game_active] = true
  session[:bet] = 0
  session[:cash] = 0
  session[:player_hand] = []
  session[:player_done] = false
  session[:dealer_hand] = []
  session[:dealer_done] = false
  suits = ['H', 'D', 'S', 'C']
  face = ['2','3','4','5','6','7','8','9','T','J','Q','K','A']
  session[:deck] = suits.product(face).shuffle!  
  session[:player_hand] << session[:deck].pop
  session[:dealer_hand] << session[:deck].pop
  session[:player_hand] << session[:deck].pop
  session[:dealer_hand] << session[:deck].pop  
end

def calculate_total(hand)
  total = 0
  aces = 0
  count = hand.map { |each| each[1] }
  count.each do |value|
    if value == 'A'
      total += 11
      aces += 1
    elsif value.to_i == 0
      total += 10    
    else
      total += value.to_i      
    end

    while total > 21 && aces > 0
      total += -10
      aces += -1
    end    
  end
  total
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

get '/game' do  
  if session[:dealer_done]
    "calculate_winner"
    
  end
  start_game unless session[:game_active]
  erb :game  
end

get '/new_game' do
  session.clear
  redirect '/'
end

get '/hit' do
  session[:player_hand] << session[:deck].pop
  redirect '/game'
end

get '/stay' do
  session[:player_done] = true
  flash[:notice] = "player done"
  redirect '/game'
end