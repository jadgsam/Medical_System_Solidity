pragma solidity ^0.5.2;

contract CentroMedicoInterface {
    function isProfessionalInMedicalCenter(address _address) public view returns(bool isProfByMedCenter);
    function setProfessionalInMedicalCenter(address _address) public;
    function getIdProfessionalInMedicalCenter(address _address) private view returns(uint id);
    function removeProfessionalInMedicalCenter(address _address) public;
    function setLeave(address _address) public;
    function getProfessionalByMedicalCenterCount() public view returns(uint quantity);
}  