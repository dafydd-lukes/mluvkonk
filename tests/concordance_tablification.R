library(testthat)
context("Converting concordance lines into tables.")

source("../mluvkonk.R")

test_that("column increments are correct when concordance lines start with a single prekryv=ano", {
  expect_equal(concLine2Html("<sp num=03 prekryv=ano>  no ale  </sp><sp num=04 prekryv=ne>  no  </sp><sp num=01 prekryv=ne>  tak ty si eště mladá holka viď  </sp><sp num=01 prekryv=ano>hele  </sp><sp num=02 prekryv=ano>  hmm . to jo  </sp><sp num=02 prekryv=ne>  za prvé váha za druhý ten kopec"),
               "<table >\n  <tr> <td align=\"right\"> 01 </td> <td>  </td> <td>  </td> <td> <sp num=\"01\" prekryv=\"ne\">  tak ty si eště mladá holka viď  </sp>  </td> <td> <sp num=\"01\" prekryv=\"ano\">hele  </sp>  </td> <td>  </td> <td>  </td> </tr>\n  <tr> <td align=\"right\"> 02 </td> <td>  </td> <td>  </td> <td>  </td> <td> <sp num=\"02\" prekryv=\"ano\">  hmm . to jo  </sp>  </td> <td> <sp num=\"02\" prekryv=\"ne\">  za prvé váha za druhý ten kopec</sp>  </td> <td>  </td> </tr>\n  <tr> <td align=\"right\"> 03 </td> <td> <sp num=\"03\" prekryv=\"ano\">  no ale  </sp>  </td> <td>  </td> <td>  </td> <td>  </td> <td>  </td> <td>  </td> </tr>\n  <tr> <td align=\"right\"> 04 </td> <td>  </td> <td> <sp num=\"04\" prekryv=\"ne\">  no  </sp>  </td> <td>  </td> <td>  </td> <td>  </td> <td>  </td> </tr>\n   </table>")
})
