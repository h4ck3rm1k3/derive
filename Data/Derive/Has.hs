{-|
    Has is a pseudo derivation.  For each field of any constructor of
    the data type, Has generates @has@/FieldName/ which returns 'True'
    if given the the given field is a member of the constructor of the
    passed object, and 'False' otherwise.
-}
module Data.Derive.Has(makeHas) where

{-
{-# TEST Computer #-}

hasSpeed :: Computer -> Bool
hasSpeed _ = True

hasWeight :: Computer -> Bool
hasWeight Laptop{} = True
hasWeight _ = False

{-# TEST Sample #-}
-}

import Language.Haskell
import Data.Derive.Internal.Derivation
import Data.List
import Data.Char


makeHas :: Derivation
makeHas = Derivation "Has" $ \(_,d) -> Right $ concatMap (makeHasField d) $
    sort $ nub $ filter (not . null) $ map fst $ concatMap ctorDeclFields $ dataDeclCtors d


makeHasField :: DataDecl -> String -> [Decl]
makeHasField d field = [TypeSig sl [name has] typ, FunBind ms]
    where
        has = "has" ++ toUpper (head field) : tail field
        typ = TyFun (dataDeclType d) (tyCon "Bool")
        (yes,no) = partition (elem field . map fst . ctorDeclFields) $ dataDeclCtors d
        match pat val = Match sl (name has) [pat] Nothing (UnGuardedRhs $ con val) (BDecls [])

        ms | null no = [match PWildCard "True"]
           | otherwise = [match (PRec (qname $ ctorDeclName c) []) "True" | c <- yes] ++ [match PWildCard "False"]
