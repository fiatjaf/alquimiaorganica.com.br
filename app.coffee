Titulo     = require('titulo').toLaxTitleCase
Reais      = require 'reais'
Promise    = require 'lie'
superagent = (require 'superagent-promise')((require 'superagent'), Promise)
talio      = require 'talio'
moment     = require 'moment'
countdown  = require 'countdown'

countdown.setLabels(
  ' milissegundo| segundo| minuto| hora| dia| semana| mês| ano| década| século| milênio'
  ' milissegundos| segundos| minutos| horas| dias| semanas| meses| anos| décadas| séculos| milênios'
  ' e '
  ' + '
  'agora'
)

{div, span, pre, nav, script, link, iframe,
 small, i, p, a, button,
 h1, h2, h3, h4, img,
 form, legend, fieldset, input, textarea, select,
 table, thead, tbody, tfoot, tr, th, td,
 ul, li} = require 'virtual-elements'

vrenderTable = require 'vrender-table'

nextFriday = moment().day(6).startOf('day').add(5, 'hours')
State = talio.StateFactory
  nextTuesday: moment().day(3)
  nextFriday: nextFriday
  timeLeft: null
  order:
    subject: localStorage.getItem 'lastNome'
    replyto: localStorage.getItem 'lastReplyTo'
    description: localStorage.getItem 'lastPedido'
    addr: localStorage.getItem 'lastAddr'
  items: []
  startFrom: 0
  show: 25
  modalOpened: null

handlers =
  fetchItems: (State) ->
    superagent
      .get('http://items.vendasalva.com.br/alquimia/items')
      .query(limit: 100)
      .end()
    .then((res) ->
      State.change
        items: -> res.body.items
    )
  sendOrder: (State, order) ->
    localStorage.setItem 'lastNome', order.subject
    localStorage.setItem 'lastReplyTo', order.replyto
    localStorage.setItem 'lastPedido', order.description
    localStorage.setItem 'lastAddr', order.addr

    superagent
      .post('http://api.boardthreads.com/ticket/55742915dd98c4a3aba3315e')
      .set('Content-Type': 'application/json')
      .send(order)
      .end()
    .then((res) ->
      console.log res.body
      here.openModal 'order-posted'
    ).catch(console.log.bind console)
  findOrders: (State, orders) ->
  openModal: (State, modalName) -> State.change 'modalOpened', modalName
  closeModal: (State) -> State.change 'modalOpened', null

vrenderMain = (state, channels) ->
  (div className: 'container',
    (div className: 'row header',
      (div className: 'col-md-2',
        (img
          className: 'logo'
          src: 'img/logo-folha-alpha.png'
        )
      )
      (div className: 'col-md-6',
        (h1 {}, 'Alquimia Orgânica na sua casa')
        (h2 {}, "> pedidos para terça, dia #{state.nextTuesday.format 'DD/MM'}")
      )
      (div className: 'col-md-4',
        (a
          className: 'btn btn-danger btn-lg btn-block'
          target: '_blank'
          href: 'como-funciona.html'
        , 'Como funciona?')
      )
    )
    (div className: 'row pedido-row',
      (div className: 'col-md-6',
        (h1 {}, 'Alguns dos nossos produtos')
        (h3 {}, 'a título de sugestão')
        (vrenderTable
          style: 'primary'
          data: ({
            'Produto': Titulo item.name
            'Preço': Reais.fromInteger(item.price) + if item.unit == '-' then '' else " / #{item.unit}"
          } for item in state.items.concat(state.items).slice(state.startFrom, state.startFrom + state.show))
          columns: ['Produto', 'Preço']
        )
        (h3 {}, 'Os preços apresentados acima são estimados com base em vendas passadas e podem estar muito errados, portanto são meramente ilustrativos.')
      )
      (div className: 'col-md-6',
        (h1 {},
          'Faça seu pedido online, receba na sua casa! '
          (span {className: 'label label-danger'},
            "você tem #{state.timeLeft} para fazer um bom pedido (até sexta)" if moment().day() < 6 and moment().day() > 2
          )
        )
        (form
          action: "http://api.boardthreads.com/ticket/55742915dd98c4a3aba3315e"
          method: 'POST'
          'ev-submit': talio.sendSubmit channels.sendOrder
        ,
          (div className: "form-group",
            (input
              type: "text"
              className: "form-control"
              name: 'subject'
              placeholder: "Nome"
            )
          )
          (div className: "form-group",
            (input
              type: "text"
              className: "form-control"
              name: 'replyto'
              placeholder: "Celular ou email"
            )
          )
          (div className: "form-group",
            (textarea
              type: "text"
              className: "form-control"
              name: 'addr'
              placeholder: "Endereço e observações para entrega"
            )
          )
          (div className: "form-group",
            (textarea
              type: "text"
              name: 'description'
              className: "form-control"
              placeholder: "Pedido"
            )
          )
          (button
            type: "submit"
            className: "btn btn-success btn-lg btn-block"
          , "Fazer pedido")
        )
        (h1 {id: "area"}, 'Área de entrega e taxas')
        (link
          rel: "stylesheet"
          href: "https://gist-assets.github.com/assets/embed-b8c853f42bc1486a246eca98739ff795.css"
        )
        (div
          id: "gist16724469"
          className: "gist"
        ,
          (div className: "gist-file gist-render",
            (iframe
              height: "420"
              width: "620"
              frameBorder: "0"
              src: "https://render.githubusercontent.com/view/geojson?url=https://gist.githubusercontent.com/fiatjaf/f3fb3621dbeb38717431/raw/alquimia.geojson"
            )
          )
        )
      )
    )
    (div className: 'row',
      (div className: 'col-md-12',
      )
    )
    (div
      className: 'modal fade ' + (if state.modalOpened == 'order-posted' then 'in' else '')
      style:
        display: if state.modalOpened == 'order-posted' then 'block' else 'none'
    ,
      (div className: 'modal-dialog',
        (div className: 'modal-content',
          (div className: 'modal-header',
            (button
              className: 'close'
              'ev-click': talio.sendClick channels.closeModal
            , '×')
          )
          (div className: 'modal-body',
            (p {}, 'Sua ordem foi enviada.')
            (p {}, 'Entraremos em contato ')
          )
          (div className: 'modal-footer',
            (button
              className: 'btn btn-default'
              'ev-click': talio.sendClick channels.closeModal
            , 'Fechar')
          )
        )
      )
    )
  )

# startup
handlers.findOrders State, localStorage.getItem 'my-orders'
(->
  updateItems = ->
    setTimeout ->
      State.change
        startFrom: ((State.get 'startFrom') + (State.get 'show')) % (State.get('items').length)
      updateItems()
    , 8000
  updateItems()
  handlers.fetchItems State
)() # items
((src) ->
  bg = new Image
  bg.src = src
  bg.onload = -> document.body.style.backgroundImage = "url(#{src})"
)('img/organicos-sobre-madeira-deitado.jpg') # background image
(setTimeout ->
  countdown State.get('nextFriday'), (ts) ->
    State.change 'timeLeft', ts.toString()
  , countdown.DAYS | countdown.HOURS | countdown.MINUTES | countdown.SECONDS
, 10) # clock
# ~

talio.run document.body, vrenderMain, handlers, State
