# SweepStocks Contract

## This is the repo for Sweepstocks Contract. To install it clone this repo, run ``npm install`` and add a ``.env`` file with a ``PRIVATE_KEY`` and a ``MUMBAI_RPC_URL``.
   
This software only works in Mumbai Network for now. 

We are currently building the front end so it can be easily used. Until there, you can deploy ``SweepStocks.sol`` passing to the constructor: 
##### a string "country name" (look available leagues below), 
##### an address "owner", 
##### a uint "duration of the contract in days".
##### After deploying the contract, send it at least 0.5 Link to register an Upkeep and pay the oracle by the end of the contract. The code for this is in ``ChainlinkConsumer.sol``

You can mint a NFT by choosing a valid id. For a league with 20 teams, the ids will be between 1 and 20. 
##### The price of the first NFT minted is 0.1 Ether (Matic), then each next one will be 0.00013 ethers more expensive.
##### If you mint more than one NFT and up to 1000 they will all cost the lowest value.
##### 100% of the value sent is added to the contract.
##### After minting a NFT you can set a price for it to be sold. You can also buy any NFT that has a price set.
##### Minting is only allowed in the first half of the contract duration.
##### When the contract ends, Chainlink will automatically set the winners in the contract and the trade is stopped.
##### If you own a NFT of the winner you can collect your prize by running ``payWinner()``

    The contract balance is distributed as follows:
      50% for the team in the 10th place when the contract ends
      25% for the 1st place
      25% for the 17th place

    Available national leagues:
      brazil
      argentina
      england
      france
      germany
      spain
      portugal
      italy

  Teams Ids (Season 2023/24)
  
    england: 
        1 Arsenal
        2 Manchester City
        3 Manchester United
        4 Tottenham Hotspur
        5 Newcastle United
        6 Liverpool
        7 Brighton & Hove Albion
        8 Brentford
        9 Fulham
        10 Chelsea
        11 Aston Villa
        12 Crystal Palace
        13 Wolverhampton Wanderers
        14 Burnley
        15 Everton
        16 Nottingham Forest
        17 Sheffield
        18 West Ham United
        19 AFC Bournemouth
        20 Luton
    
    brazil: 
        1 America MG
        2 Athletico Paranaense
        3 Atletico MG
        4 Bahia
        5 Botafogo FR
        6 Corinthians
        7 Coritiba
        8 Cruzeiro
        9 Cuiaba
        10 Flamengo
        11 Fluminense
        12 Fortaleza
        13 Goias
        14 Gremio
        15 Internacional
        16 Palmeiras
        17 Bragantino
        18 Santos FC
        19 Sao Paulo
        20 Vasco da Gama
    
    spain: 
        1 Barcelona
        2 Real Madrid
        3 Atletico Madrid
        4 Real Sociedad
        5 Real Betis
        6 Villarreal
        7 Athletic Bilbao
        8 Rayo Vallecano
        9 Osasuna
        10 Celta Vigo
        11 Mallorca
        12 Girona
        13 Getafe
        14 Sevilla
        15 Cadiz
        16 Las Palmas
        17 Granada
        18 Valencia
        19 Almeria
        20 Alavés  

    italy: 
        1 Napoli
        2 Lazio
        3 Inter
        4 AC Milan
        5 Roma
        6 Atalanta
        7 Juventus
        8 Udinese
        9 Fiorentina
        10 Bologna
        11 Torino
        12 Sassuolo
        13 Monza
        14 Empoli
        15 Lecce
        16 Salernitana
        17 Cagliari
        18 Verona
        19 Frosinone
        20 Genoa
    
    germany: 
        1 Borussia Dortmund
        2 Bayern Munich
        3 Union Berlin
        4 Freiburg
        5 RB Leipzig
        6 Eintracht Frankfurt
        7 Wolfsburg
        8 Bayer Leverkusen
        9 Mainz
        10 Borussia M:engladbach
        11 Werder Bremen
        12 Augsburg
        13 FC Cologne
        14 Bochum
        15 Hoffenheim
        16 Darmstadt
        17 Heidenheim
        18 VfB Stuttgart

    france: 
        1 Paris Saint-Germain
        2 Marseille
        3 Lens
        4 Monaco
        5 Rennes
        6 Lille
        7 Nice
        8 Lorient
        9 Reims
        10 Lyon
        11 Montpellier
        12 Toulouse
        13 Clermont Foot
        14 Nantes
        15 Strasbourg
        16 Brest
        17 Le Havre
        18 Metz

    argentina: 
        1 River Plate
        2 San Lorenzo de Almagro
        3 Defensa y Justicia
        4 Racing Club
        5 Lanus
        6 Newell's Old Boys
        7 Rosario Central
        8 Talleres
        9 Instituto Cordoba
        10 Velez Sarsfield
        11 CA Huracan
        12 Godoy Cruz Antonio Tomba
        13 Argentinos Juniors
        14 Boca Juniors
        15 Belgrano
        16 Club Atletico Platense
        17 Barracas Central
        18 Banfield
        19 Sarmiento
        20 Independiente
        21 Arsenal de Sarandi
        22 Atletico Tucuman
        23 Gimnasia La Plata
        24 Colon
        25 Central Cordoba de Santiago
        26 Tigre
        27 Estudiantes de La Plata
        28 Union
  
    portugal: 
        1 Benfica
        2 FC Porto
        3 SC Braga
        4 Sporting CP
        5 Vitoria de Guimaraes
        6 Arouca
        7 Casa Pia AC
        8 Rio Ave
        9 Famalicao
        10 Vizela
        11 Chaves
        12 Boavista
        13 Gil Vicente
        14 Portimonense
        15 Estoril
        16 Moreirense
        17 Farense
        18 CF Estrela Amadora

  
