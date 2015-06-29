Titulo     = require('titulo').toLaxTitleCase
Reais      = require 'reais'
Promise    = require 'lie'
superagent = (require 'superagent-promise')((require 'superagent'), Promise)
talio      = require 'talio'
moment     = require 'moment'
countdown  = require 'countdown'

countdown.setLabels(
  'ms|s|m|h| dia| semana| mês| ano| década| século| milênio'
  'ms|s|m|h| dias| semanas| meses| anos| décadas| séculos| milênios'
  ' e '
  ', '
  'agora'
)

{div, span, pre, nav, script, link, iframe,
 small, i, p, a, button,
 h1, h2, h3, h4, img,
 form, legend, fieldset, input, textarea, select,
 table, thead, tbody, tfoot, tr, th, td,
 ul, li} = require 'virtual-elements'

vrenderTable = require 'vrender-table'

weekday = moment().isoWeekday()
nextFriday = moment().isoWeekday(if weekday <= 5 then 5 else 1).startOf('day').add(5, 'hours')
nextMonday = moment().isoWeekday(if weekday <= 1 then 1 else 8).startOf('day')
nextTuesday = moment().isoWeekday(if weekday <= 2 then 2 else 9)
State = talio.StateFactory
  timeLeft: null
  order:
    subject: localStorage.getItem 'lastNome'
    replyto: localStorage.getItem 'lastReplyTo'
    text: localStorage.getItem 'lastPedido'
    description: localStorage.getItem 'lastAddr'
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
    here = @
    localStorage.setItem 'lastNome', order.subject
    localStorage.setItem 'lastReplyTo', order.replyto
    localStorage.setItem 'lastPedido', order.text
    localStorage.setItem 'lastAddr', order.description

    superagent
      .post('http://api.boardthreads.com/ticket/55742915dd98c4a3aba3315e')
      .withCredentials()
      .set('Content-Type': 'application/json')
      .set('Accept': 'application/json')
      .send(order)
      .end()
    .then((res) ->
      console.log res.body
      here.openModal State, 'order-posted'
      window._fbq.push(['track', '6032144402955', {'value':'0.00','currency':'BRL'}])
      ma('pedido', order.subject)
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
        (h2 {}, "> pedidos para terça, dia #{nextTuesday.format 'DD/MM'}")
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
            "você tem #{state.timeLeft.string} para fazer seu pedido (até #{if state.timeLeft.to is nextFriday then 'sexta' else 'segunda'})"
          ) if state.timeLeft
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
              defaultValue: state.order.subject or ''
            )
          )
          (div className: "form-group",
            (input
              type: "text"
              className: "form-control"
              name: 'replyto'
              placeholder: "Celular ou email"
              defaultValue: state.order.replyto or ''
            )
          )
          (div className: "form-group",
            (textarea
              type: "text"
              className: "form-control"
              name: 'description'
              placeholder: "Endereço e observações para entrega"
              defaultValue: state.order.description or ''
            )
          )
          (div className: "form-group",
            (textarea
              type: "text"
              name: 'text'
              className: "form-control"
              placeholder: "Pedido"
              defaultValue: state.order.text or ''
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
            (p {}, 'Seu pedido foi enviado.')
            (p {}, 'Em algum momento nós entraremos em contato para confirmar o valor e a entrega.')
            (p {}, 'Se você tiver mais alguma coisa a acrescentar ou alterar no pedido, envie de novo explicando suas alterações.')
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
  now = moment()
  if now.isBefore(nextFriday) and now.isAfter(moment().isoWeekday(2))
    target = nextFriday
  else if now.isBefore(nextMonday)
    target = nextMonday
  else
    State.change 'timeLeft', null
    return

  countdown target, (ts) ->
    State.change 'timeLeft', ->
      string: ts.toString()
      to: target
  , countdown.DAYS | countdown.HOURS | countdown.MINUTES | countdown.SECONDS
, 10) # clock
# ~

talio.run document.body, vrenderMain, handlers, State
