pragma solidity ^0.5.2;
import "./sistemamedicointerface.sol";
/*
Este contrato permite gestionar al medico dentro del "Centro Medico" utilizando la variable 
professionalByMedicalCenter para matener relacion. Por otro lado se informa al "sistema central" cuando dicha relacion se produce 
La idea es poder tener un control de profesionales a nivel de centro, gestionar las bajas/vacaciones o
ausencias por institucion y en el futuro dejar la posibilidad de extender otras funcionalidades sin depender del sistema central.
Actualmente solo se puede deshabilitar al medico en el centro medico "indicando" sin una logica compleja que no esta operativo 
para el centro en este momento.
*/

contract CentroMedico {
    event LogRecordWrite(address triggerId, address impactedId, uint dateTime);
    mapping (address => ProfessionalInMedicalCenter[]) professionalByMedicalCenter;
    uint professionalByMedicalCenterCount;
    
    SistemaMedicoInteface sMI; //Variable que permite acceder al contrato de Sistema Medico

    //Se inicializa manualmente la variable de Sistema Medico pasandole la direccion correspondiente.
    function setSistemaMedicoAddress(address _address) external{
        sMI = SistemaMedicoInteface(_address);
    }
    
    //Restringe el uso por parte de un manager
    modifier onlyManager() {
        require(sMI.isAdmin(msg.sender), "No es manager del sistema");
        _;
    }
    
    //Restringe el uso por parte del centro médico
    modifier onlyMedicalCenter() {
        require(sMI.isMedicalCenter(msg.sender), "No es un Centro Médico del sistema");
        _;
    }
    
    //Restringe el uso por parte del  médico
    modifier onlyProfessional() {
        require(sMI.isProfessional(msg.sender), "No es un Médico del sistema");
        _;
    }
    
    /*Estructura basica del centro medico 

    */
    struct ProfessionalInMedicalCenter {
        address professionalId;
        bool active;
    }
    
    //*********************      
    //*********************  
    
    //Valida la existencia del profesional en el "Centro Medico" quien lo hace es el propio "Centro Medico"
    function isProfessionalInMedicalCenter(address _address) public view returns(bool isProfByMedCenter) {
        ProfessionalInMedicalCenter[] memory ProfessionalInMedicalCenterAux = professionalByMedicalCenter[msg.sender];
        for(uint i=0; i < ProfessionalInMedicalCenterAux.length; i++) {
            if (ProfessionalInMedicalCenterAux[i].professionalId == _address) {
                return true;       
            }
        }
        return false;
    }
    
    //Valida que el profesional en el "Centro Medico" se encuentre activo
    function isProfessionalInMedicalCenterActive(address _addressProfessional, address _addressMedicalCenter) public view onlyProfessional() returns(bool isProfByMedCenter) {
        ProfessionalInMedicalCenter[] memory ProfessionalInMedicalCenterAux = professionalByMedicalCenter[_addressMedicalCenter];
        for(uint i=0; i < ProfessionalInMedicalCenterAux.length; i++) {
            if (ProfessionalInMedicalCenterAux[i].professionalId == _addressProfessional) {
                return true;       
            }
        }
        return false; 
    }
    
    //Asigna el profesinal al centro medico
    function setProfessionalInMedicalCenter(address _address) public onlyMedicalCenter() {
        ProfessionalInMedicalCenter memory doctorInformation;
        require(!isProfessionalInMedicalCenter(_address) &&  _address != address(0), "Profesional ya existe en el Centro Médico");
        require(sMI.isProfessional(_address), "El médico ingresado no es reconocido por sistema médico");
        doctorInformation.professionalId = _address;
        doctorInformation.active = true;
        professionalByMedicalCenter[msg.sender].push(doctorInformation);
        sMI.setCentroMedicoToProfessional(msg.sender, _address);
        emit LogRecordWrite(msg.sender, _address, now);
    }
    
    //Obtiene la posicion (id) en el array del centro que tiene el medico quien lo hace es el propio "Centro Medico" 
    function getIdProfessionalInMedicalCenter(address _address) public view onlyMedicalCenter() returns(uint id){
        ProfessionalInMedicalCenter[] memory ProfessionalInMedicalCenterAux = professionalByMedicalCenter[msg.sender];
        for(uint i=0; i < ProfessionalInMedicalCenterAux.length; i++) {
            if (ProfessionalInMedicalCenterAux[i].professionalId == _address) {
               return i;
            }
        }      
    }
    
    //Elimina al profesional del centro
    function removeProfessionalInMedicalCenter(address _address) public onlyMedicalCenter() {
        require(isProfessionalInMedicalCenter(_address) && _address != address(0), "Profesional no existe en el Centro Médico");
        removeArrayPMC(getIdProfessionalInMedicalCenter(_address));    
        emit LogRecordWrite(msg.sender, _address, now);
    }
    
    //funcion complementaria para eliminar el elemento del array
    function removeArrayPMC(uint index) private {
        ProfessionalInMedicalCenter[] storage  ProfessionalInMedicalCenterAux = professionalByMedicalCenter[msg.sender];
        if (index >= ProfessionalInMedicalCenterAux.length) return;

        for (uint i = index; i<ProfessionalInMedicalCenterAux.length-1; i++){
            ProfessionalInMedicalCenterAux[i] = ProfessionalInMedicalCenterAux[i+1];
        }
        delete ProfessionalInMedicalCenterAux[ProfessionalInMedicalCenterAux.length-1];
        ProfessionalInMedicalCenterAux.length--;
        professionalByMedicalCenter[msg.sender] = ProfessionalInMedicalCenterAux;
    }
    
    //funcion que permite asignar la baja logica del centro (baja/vacaciones/ausencia)
    function setLeave(address _address) public onlyMedicalCenter() {
        require(isProfessionalInMedicalCenter(_address) && _address != address(0), "Profesional no existe en el Centro Médico");
        professionalByMedicalCenter[msg.sender][getIdProfessionalInMedicalCenter(_address)].active = false;
        emit LogRecordWrite(msg.sender, _address, now);
    }    
    
    //Devuelve el total de medicos existentes en un centro medico
    function getProfessionalByMedicalCenterCount() public view onlyMedicalCenter() onlyManager() returns(uint quantity) {
        return professionalByMedicalCenter[msg.sender].length;
    }
}