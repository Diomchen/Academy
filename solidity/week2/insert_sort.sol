// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
contract InsertSort{
    function insert_sort(uint [] memory arr) public pure returns(uint[] memory){
        for (uint i=1; i<arr.length; i++){
            uint temp=arr[i];
            uint j=i;
            while((j>=1) && (temp < arr[j-1])){
                arr[j] = arr[j-1];
                j--;
            }
            arr[j] = temp;
        }
        return(arr);
    }
    
}