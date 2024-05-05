// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

contract Auction {
    address private owner;
    uint256 public initialDate; // Fecha de inicio de la subasta en timestamp
    uint256 public duration; // Duración de la subasta en segundos
    uint256 public initialPrice; // Precio inicial del NFT
    uint256 public actualPrice; // Precio actual de la subasta
    uint256 public winnerPrice; // Precio final de venta
    address private winner; // Dirección del ganador de la subasta
    uint256 public commission; // Comisión porcentaje del precio de venta
    uint256 public endDate; // Fecha de finalización de la subasta
    bool private finished; // Indicador de si la subasta ha finalizado
    address[] private bidders; // Lista de ofertantes
    mapping(address => uint256) private offers; // Ofertas de los ofertantes (públicas y privadas)
    mapping(address => uint256) private publicOffers; // Ofertas públicas
    event NewOffer(address bidder, uint256 offer, bool secret); // Evento emitido cuando se realiza una nueva oferta
    event AuctionFinished(address winner, uint256 offer); // Evento emitido cuando finaliza la subasta

    constructor() {
        owner = msg.sender;
    }

    //Modificadores para restringir el acceso a ciertas funciones

    modifier onlyOwner() {
        require(msg.sender == owner, "Solo el propietario puede realizar esta operacion");
        _;
    }

    modifier onlyBeforeEnd() {
        require(block.timestamp < endDate, "La subasta ha finalizado");
        _;
    }

    modifier onlyAuctionStarted() {
        require(block.timestamp >= initialDate, "La subasta no ha comenzado");
        _;
    }

    modifier onlyAfterEnd() {
        require(block.timestamp >= endDate, "La subasta no ha finalizado");
        _;
    }

    //Funciones

    //Iniciar subasta
    function startAuction(uint256 _initialPrice, uint256 _startDate, uint256 _duration) public onlyOwner {
        initialPrice = _initialPrice;
        actualPrice = _initialPrice;
        initialDate = _startDate;
        duration = _duration;
        endDate = initialDate + duration;
    }

    //Ofertar
    function bid(bool _secret, uint256 _amount) public payable onlyBeforeEnd onlyAuctionStarted {
        require(_amount > actualPrice, "La oferta debe ser mayor al precio actual");
        if (offers[msg.sender] == 0) {
            bidders.push(msg.sender);
        }
        actualPrice = _amount;
        winnerPrice = _amount;
        winner = msg.sender;
        if (_secret) {
            offers[msg.sender] = _amount;
        } else {
            offers[msg.sender] = _amount;
            publicOffers[msg.sender] = _amount;
        }
        emit NewOffer(msg.sender, _amount, _secret);
    }

    //Finalizar subasta
    function finishAuction() public onlyOwner {
        uint256 max = 0;
        address winnerAddress;
        for (uint256 i = 0; i < bidders.length; i++) {
            if (offers[bidders[i]] > max) {
                max = offers[bidders[i]];
                winnerAddress = bidders[i];
            }
        }
        winner = winnerAddress;
        winnerPrice = max;
        finished = true;
        emit AuctionFinished(winner, winnerPrice);
    }

    //Mostrar ganador
    function showWinner() public view returns(address, uint256) {
        return (winner, winnerPrice);
    }

    //Mostrar ofertas
    function showOffers() public view returns(address[] memory, uint256[] memory) {
        if(msg.sender == owner){
            uint256 count = bidders.length;
            address[] memory biddersToShow = new address[](count);
            uint256[] memory offersToShow = new uint256[](count);
            uint256 index = 0;
            for (uint256 i = 0; i < bidders.length; i++) {
                biddersToShow[index] = bidders[i];
                offersToShow[index] = offers[bidders[i]];
                index++;
            }
            return (biddersToShow, offersToShow);
        }else{
            uint256 count = bidders.length;
            address[] memory biddersToShow = new address[](count);
            uint256[] memory offersToShow = new uint256[](count);
            uint256 index = 0;
            for (uint256 i = 0; i < bidders.length; i++) {
                if (publicOffers[bidders[i]] != 0) {
                    biddersToShow[index] = bidders[i];
                    offersToShow[index] = publicOffers[bidders[i]];
                    index++;
                }
            }
            return (biddersToShow, offersToShow);
        }
    }

    // Retirar fondos del contrato
    function withdraw() public {
        require(finished || block.timestamp >= endDate, "La subasta no ha finalizado");
        if (msg.sender != winner) {
            uint256 amount;
            if (offers[msg.sender] != 0) {
                amount = offers[msg.sender];
            } else {
                amount = publicOffers[msg.sender];
            }
            offers[msg.sender] = 0;
            payable(msg.sender).transfer(amount - calculateCommission(amount));
        }
    }

    // Retirar depósito
    function withdrawDeposit() public {
        require(block.timestamp >= endDate, "La subasta aun no ha finalizado");
        require(msg.sender != winner, "Usted no esta autorizado para retirar el deposito");
        uint256 amount;
        if (offers[msg.sender] != 0) {
            amount = offers[msg.sender];
        } else {
            amount = publicOffers[msg.sender];
        }
        offers[msg.sender] = 0;
        payable(msg.sender).transfer(amount - calculateCommission(amount));
    }

    // Calcular la comisión
    function calculateCommission(uint256 amount) private pure returns(uint256) {
        return amount * 2 / 100;
    }

}