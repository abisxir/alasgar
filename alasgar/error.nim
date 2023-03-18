type 
    AlasgarError* = object of Defect 

proc newAlasgarError*(message: string): ref AlasgarError = 
    newException(AlasgarError, message)