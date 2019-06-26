pragma solidity ^0.5.2;
//Se exponen todas las funciones publicas de Sistema Medico
contract SistemaMedicoInteface {
    function isAdmin(address _address) public view returns(bool isAdm);
    function setAdmin(address _address) public;
    function removeAdmin(address _address) public;
    function getAdminCount() public view returns(uint quantity);
    function isProfessional(address _address) public view returns(bool isProf);
    function setProfessional(address _address, uint[] memory _specialities) public;
    function removeProfessional(address _address) public;
    function getProfessionalCount() public view returns(uint quantity);
    function getProfessionalSpecialities(address _address) public view returns (uint[] memory specialities);
    function setMedicalSpeciality(string memory _name) public;
    function getIdMedicalSpeciality(string memory _name) public view returns (uint resultado);
    function isMedicalCenter(address _address) public view returns(bool isMedCenter);
    function setMedicalCenter(address _address) public;
    function removeMedicalCenter(address _address) public;
    function getMedicalCenterCount() public view returns(uint quantity);
    function isMedicalCenterInProfessional(address _medicalCenter, address _professional) public view returns(bool result); 
    function setCentroMedicoToProfessional(address _medicalCenter, address _professional) public; 
}  
