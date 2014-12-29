BlackJack Week 4!
=================

https://guarded-ridge-3744.herokuapp.com

This is the week three version of the Sinatra blackjack app. I learned a couple of tricks along the way. I have a slightly different format than was used in the solutions. This more or less eliminated the need for the helper method on the win!/lose!/tie!. I didn't really like their messages anyway.

The game correctly does the blackjack portion (21 != blackjack | (21 + count == 2) == blackjack). I resized the cards because it wasn't fitting correctly on my monitor (and just because) there is an odd bug in which occasionally the cards display at a larger size which I've yet to find.

You'll note I've moved all the buttons to the bottom--creates minimal mouse movement when operating.

I have now implemented betting, ajax, and improved on the messages. There is more that could be added, but I think it has given me enough of a grasp on HTTP that I can move forward.
