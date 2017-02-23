x <- data.frame(systems=1:9,
    bstatic=c(30, 62,  155, 9,  500,  220, 27,  157, 53),
    pdinamic=c(77, 122, 354, 20, 1088, 539, 146, 844, 219))

# derive the difference
x$diff <- x$p-x$b

mean(x$bstatic)

mean(x$pdinamic)

mean(x$pdinamic)-mean(x$bstatic)

boxplot(x$diff)

boxplot(x$bstatic, x$pdinamic, names= c("Static", "Dinamic"), main="Recall 1")

qqnorm(x$diff)
qqline(x$diff)

shapiro.test(x$diff)

t.test(x$pdinamic, x$bstatic, paired=T, alternative="greater")
