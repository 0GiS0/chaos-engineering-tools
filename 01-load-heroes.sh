curl --request GET \
  --url http://$1/api/hero 

curl --request POST \
  --url http://$1/api/hero \
  --header 'content-type: application/json' \
  --data '{"name": "Arrow","alterEgo": "Oliver Queen","description": "Multimillonario playboy Oliver Queen (Stephen Amell), quien, cinco años después de estar varado en una isla hostil, regresa a casa para luchar contra el crimen y la corrupción como un vigilante secreto cuya arma de elección es un arco y flechas."}'

curl --request POST \
  --url http://$1/api/hero \
  --header 'content-type: application/json' \
  --header 'user-agent: vscode-restclient' \
  --data '{"name": "Batman","alterEgo": "Bruce Wayne","description": "Un multimillonario magnate empresarial y filántropo dueño de Empresas Wayne en Gotham City. Después de presenciar el asesinato de sus padres, el Dr. Thomas Wayne y Martha Wayne en un violento y fallido asalto cuando era niño, juró venganza contra los criminales, un juramento moderado por el sentido de la justicia."}'

curl --request POST \
  --url http://$1/api/hero \
  --header 'content-type: application/json' \
  --header 'user-agent: vscode-restclient' \
  --data '{"name": "Captain America","alterEgo": "Steve Rogers","description": "Un joven frágil mejorado a la cima de la perfección humana por un suero experimental S.S.S. (Suero supersoldado) para ayudar a los esfuerzos inminentes del gobierno de Estados Unidos en la Segunda Guerra Mundial. Cerca del final de la guerra, queda atrapado en el hielo y sobrevive en animación suspendida hasta que es descongelado en el presente."}'