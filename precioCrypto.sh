#!/usr/bin/env bash

if [ -z $1 ] && [ -z $2 ]
then
  . arrayCrypto
else
  COIN=$1
  CCOIN=$2
  if [ -z $2 ] 
  then
    CCOIN=1
  fi
fi

API=1c8c312d-797d-4764-b8fe-eebc92225c17
COUNT=0
MONEY_EUR=0
MONEY_BTC=0
i=0

function mantisa()
{
if (echo "$1" | grep -E "e-") > /dev/null
then
  sin=`echo $1 | cut -d "e" -f 1`
  man=`echo $1 | cut -d "-" -f 2`
  num=$(echo "scale=10; ${sin} * 10 ^ -${man}" | bc -l)
  echo $num
else
  echo $1
fi
}

#curl -s "https://api.coinmarketcap.com/v1/ticker/?convert=EUR&limit=0" | jq -r '.[]' > json
curl -s -H "X-CMC_PRO_API_KEY: ${API}" "https://pro-api.coinmarketcap.com/v1/cryptocurrency/listings/latest?limit=5000&convert=EUR" | jq '.[]' | sed 1,9d | jq '.[]' > jsonEUR
curl -s -H "X-CMC_PRO_API_KEY: ${API}" "https://pro-api.coinmarketcap.com/v1/cryptocurrency/listings/latest?limit=5000&convert=BTC" | jq '.[]' | sed 1,9d | jq '.[]' > jsonBTC

for coin in ${COIN[@]}
do

  # el m 1 del grep es para que solo salga el 1 resultado (en monedas como eth hay varios resultados con slug $coin)
  existe=`cat jsonBTC | jq -r '. | @json' | grep -m 1 "\"slug\":\"${coin}\"" | jq -r '.slug'`
  if [[ "$existe" == "$coin" ]]
  then

echo -e "------------- \e[1;34m$coin\e[0m -------------"

  coinNewBTC=(`cat jsonBTC | jq -r '. | @json' | grep -m 1 "\"slug\":\"${coin}\"" | jq -r '.id, .quote.BTC.price'`)
  PrecioBTC=$(mantisa ${coinNewBTC[1]})
  TOTAL_BTC=$(echo "scale=10; $PrecioBTC * ${CCOIN[i]}" | bc -l)
  echo "BTC   $PrecioBTC * ${CCOIN[i]} = "$TOTAL_BTC
  coinNewEUR=(`cat jsonEUR | jq -r '. | @json' | grep "\"slug\":\"${coin}\"" | jq -r '.id, .quote.EUR.price'`)
  PrecioEUR=$(mantisa ${coinNewEUR[1]})
  TOTAL_EUR=$(echo "scale=10; $PrecioEUR * ${CCOIN[i]}" | bc -l)
  echo "Euros $PrecioEUR * ${CCOIN[i]} = "$TOTAL_EUR €
  echo "----------------------------"
  i=$((i+1))

  MONEY_BTC=$(echo "scale=10; $MONEY_BTC + $TOTAL_BTC" | bc -l)
  MONEY_EUR=$(echo "scale=10; ${MONEY_EUR} + ${TOTAL_EUR}" | bc -l)

  else
    echo -e "\e[0;31m$coin\e[0m no aparece listada en coinmarketcap"
    i=$((i+1))
    echo "----------------------------"
  fi

done

echo "*******************"
echo -e $MONEY_BTC BTC en total 
echo -e $MONEY_EUR Euros en total 
echo "*******************"

# Limpiamos
rm -rf jsonEUR jsonBTC
