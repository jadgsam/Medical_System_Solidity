pragma solidity ^0.5.2;

import "github.com/OpenZeppelin/zeppelin-solidity/contracts/ownership/Ownable.sol";
/*
Este contrato permite gestionar 3 actores (admins, profesionales, centros medicos)
abajo explico las variables principales
admin: mapa de direcciones autorizada por el owner del contrato 
para dar de alta => "Especialidades", "Profesionales Medicos", "Centros Medicos"
professional: mapa de direcciones de medicos en el sistema;
medicalCenter: mapa de direcciones de centros medicos en el sistema;
speciality: array de especialidades medicas
*/
contract SistemaMedico is Ownable{
    event LogRecordWrite(address triggerId, address impactedId, uint dateTime);

    string[] speciality; 
    mapping (address => bool) private admin; 
    mapping (address => Profesional) private  professional;
    mapping (address => bool) private medicalCenter;
    
    uint adminCount=0;
    uint professionalCount=0;
    uint centerCount=0;
    
    struct Profesional {
        bool active;
        uint[] idSpeciality; //se asocian especialidades al medico para su clasificación
        address[] medicalCenter;
    }
    
    //Restringe el uso por parte de un manager
    modifier onlyManager() {
        require(isAdmin(msg.sender), "No es manager del sistema");
        _;
    }
    
    //Restringe el uso por parte del centro médico
    modifier onlyMedicalCenter() {
        require(isMedicalCenter(msg.sender), "No es un Centro Médico del sistema");
        _;
    }
    
    //*********************
    
    //valida que la direccion pertenezca a un admin
    function isAdmin(address _address) public view returns(bool isAdm) {
        return admin[_address];
    }
    
    //Permite agregar un nuevo admin pero solo siendo owner del contrato
    function setAdmin(address _address) public onlyOwner() {
        require(!isAdmin(_address) && _address != address(0), "Administrador ya existe");
        admin[_address] = true;
        adminCount++;
        emit LogRecordWrite(msg.sender, _address, now);
    }
    
    //Permite remover un admin pero solo siendo owner del contrato
    function removeAdmin(address _address) public onlyOwner() {
        require(isAdmin(_address) && _address != address(0), "Administrador no existe");
        admin[_address] = false;
        delete admin[_address];
        adminCount--;
        emit LogRecordWrite(msg.sender, _address, now);
    }
    
    //Devuelve la cantidad admins pero solo siendo owner del contrato o admin del sistema medico
    function getAdminCount() public view onlyManager() onlyOwner() returns(uint quantity) {
        return adminCount;
    }
    
    //*********************      
    //*********************  
    
    //Confirma si el medico esta activo o no
    function isProfessional(address _address) public view returns(bool isProf) {
        return professional[_address].active;
    }
    
    //Permite agregar un nuevo profesional medico pero solo siendo manager del contrato
    function setProfessional(address _address, uint[] memory _specialities) public onlyManager() {
        require(!isProfessional(_address) && _address != address(0), "Profesional ya existe");
        require(!isAdmin(_address), "No puede ingresar a un administrador como Medico");
        require(!isMedicalCenter(_address), "No puede ingresar a un centro  medico como Medico");
        professional[_address].active = true;
        professional[_address].idSpeciality = _specialities;
        professionalCount++;
        emit LogRecordWrite(msg.sender, _address, now);
    }
    
    //Permite remover un nuevo profesional medico pero solo siendo manager del contrato
    function removeProfessional(address _address) public onlyManager() {
        require(isProfessional(_address) && _address != address(0), "Profesional no existe");
        professional[_address].active = false;
        delete professional[_address].idSpeciality;
        delete professional[_address];
        professionalCount--;
        emit LogRecordWrite(msg.sender, _address, now);
    }
    
    //devuelve el valor del contador de medicos
    function getProfessionalCount() public view onlyManager() returns(uint quantity) {
        return professionalCount;
    }
    
    //devuelve las especialidades que posee un medico 
    function getProfessionalSpecialities(address _address) public view onlyManager() returns (uint[] memory specialities){
        return professional[_address].idSpeciality;
    }
    
    //*********************      
    //*********************  
    
    // gestiona la creacion de Especialidades Medicas (solo puede hacerlo un manager)
    function setMedicalSpeciality(string memory _name) public onlyManager() {
        speciality.push(_name);
    }
    
    //Devuelve el Id de una especialidad siendo admin del sistema medico
    function getIdMedicalSpeciality(string memory _name) public view onlyManager returns (uint resultado) {
        for (uint i=0;speciality.length-1>=i;i++){
            if (keccak256(abi.encodePacked((_name))) == keccak256(abi.encodePacked((speciality[i])))) {
                return i;
            }
        }
    }
    
    //*********************      
    //*********************  
    
    // valida si el Centros Médico existe o no
    function isMedicalCenter(address _address) public view returns(bool isMedCenter) {
        return medicalCenter[_address];
    }
    
    // Permite crear un nuevo centro medico solo al manager
    function setMedicalCenter(address _address) public onlyManager() {
        require(!isMedicalCenter(_address) && _address != address(0), "Centro Médico ya existe");
        require(!isProfessional(_address), "No puede ingresar un medico como centro medico");
        require(!isAdmin(_address), "No puede ingresar un administrador como centro medico");
        medicalCenter[_address] = true;
        centerCount++;
        emit LogRecordWrite(msg.sender, _address, now);
    }
    
    // Permite remover un centro medico solo al manager
    function removeMedicalCenter(address _address) public onlyManager() {
        require(isMedicalCenter(_address) && _address != address(0), "Centro Médico  no existe");
        medicalCenter[_address] = false;
        delete medicalCenter[_address];
        centerCount--;
        emit LogRecordWrite(msg.sender, _address, now);
    }
    
    //Devuelve la cantidad centros medicos pero solo siendo admin del sistema medico
    function getMedicalCenterCount() public view onlyManager() returns(uint quantity) {
        return centerCount;
    }
    
    //valida que el centro medico este asociado al medico
    function isMedicalCenterInProfessional(address _medicalCenter, address _professional) public view returns(bool result) {
        for(uint i=0;i<professional[_professional].medicalCenter.length;i++){
            if (professional[_professional].medicalCenter[i] == _medicalCenter) {
                return true;
            } 
        }
        return false;
    }
    //asigna un centro medico a un medico
    function setCentroMedicoToProfessional(address _medicalCenter, address _professional) public {
        if (!isMedicalCenterInProfessional( _medicalCenter,  _professional)) {
            professional[_professional].medicalCenter.push(_medicalCenter);
        }
    }

    //*********************      
    //*********************  
}